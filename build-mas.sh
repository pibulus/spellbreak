#!/bin/bash

set -euo pipefail

APP_NAME="Spellbreak"
BUILD_ROOT="build"
APP_BUNDLE="${BUILD_ROOT}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
APP_INFO_PLIST="${CONTENTS_DIR}/Info.plist"
APP_BINARY="${CONTENTS_DIR}/MacOS/${APP_NAME}"
PROVISION_PROFILE="Spellbreak_MAS.provisionprofile"
ENTITLEMENTS="Spellbreak.mas.entitlements"
DIST_DIR="dist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "Sources/Spellbreak/Resources/Info.plist")
PKG_PATH="${DIST_DIR}/${APP_NAME}-v${VERSION}-mas.pkg"

TEAM_ID="V433H655PN"
BUNDLE_ID="com.pabloalvarado.spellbreak"
APP_SIGN_IDENTITY="Apple Distribution: Pablo Alvarado (${TEAM_ID})"
INSTALLER_SIGN_IDENTITY="3rd Party Mac Developer Installer: Pablo Alvarado (${TEAM_ID})"

PROFILE_PLIST="$(mktemp)"
cleanup() {
    rm -f "$PROFILE_PLIST"
}
trap cleanup EXIT

# --- Preflight: everything that can fail fast, before a two-arch release build ---

# App Store Connect works out which Xcode/SDK built the app from DT* keys in
# Info.plist. `swift build` never writes them, so they're stamped below from the
# Xcode that did the build. Command Line Tools alone can't vouch for that.
if ! XCODE_VERSION_OUTPUT=$(xcodebuild -version 2>/dev/null); then
    echo "❌ Full Xcode is required for App Store builds"
    echo "   xcode-select -p currently points at: $(xcode-select -p)"
    echo "   Fix: sudo xcode-select -s /Applications/Xcode.app"
    exit 1
fi

if [[ ! -f "$PROVISION_PROFILE" ]]; then
    echo "❌ Missing provisioning profile: ${PROVISION_PROFILE}"
    echo "   Download a Mac App Store distribution provisioning profile for"
    echo "   ${BUNDLE_ID} from developer.apple.com, save it"
    echo "   as '${PROVISION_PROFILE}' in this directory, then re-run."
    exit 1
fi

# A development or wrong-app profile only bounces after the upload has been
# processed, so check it here instead.
security cms -D -i "$PROVISION_PROFILE" > "$PROFILE_PLIST"
PROFILE_APP_ID=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:com.apple.application-identifier" "$PROFILE_PLIST" 2>/dev/null || true)
if [[ "$PROFILE_APP_ID" != "${TEAM_ID}.${BUNDLE_ID}" ]]; then
    echo "❌ ${PROVISION_PROFILE} is for '${PROFILE_APP_ID:-unknown}', expected '${TEAM_ID}.${BUNDLE_ID}'"
    exit 1
fi
if /usr/libexec/PlistBuddy -c "Print :ProvisionedDevices" "$PROFILE_PLIST" >/dev/null 2>&1; then
    echo "❌ ${PROVISION_PROFILE} is a development profile (it lists devices)."
    echo "   Download the Mac App Store distribution profile instead."
    exit 1
fi

# Captured, not piped into grep -q: under pipefail an early-exiting grep can
# SIGPIPE the writer and fail the check even on a match.
INSTALLED_IDENTITIES=$(security find-identity -v)
for identity in "$APP_SIGN_IDENTITY" "$INSTALLER_SIGN_IDENTITY"; do
    if [[ "$INSTALLED_IDENTITIES" != *"$identity"* ]]; then
        echo "❌ Signing identity not in your keychain: ${identity}"
        echo "   security find-identity -v   lists what's installed"
        exit 1
    fi
done

# --- Build ---

echo "📦 Building unsigned app via build-app.sh..."
./build-app.sh

# The Mac App Store lists Spellbreak for Intel and Apple silicon; build-app.sh
# quietly falls back to arm64-only when the x86_64 build fails, which is fine for
# local testing but not for this.
ARCHS=$(lipo -archs "$APP_BINARY")
if [[ "$ARCHS" != *arm64* || "$ARCHS" != *x86_64* ]]; then
    echo "❌ App Store build must be universal (arm64 + x86_64); got: ${ARCHS}"
    exit 1
fi

echo "🏷  Stamping toolchain keys into Info.plist..."
XCODE_VERSION=$(echo "$XCODE_VERSION_OUTPUT" | awk '/^Xcode/ {print $2}')          # e.g. 26.0.1
XCODE_BUILD=$(echo "$XCODE_VERSION_OUTPUT" | awk '/^Build version/ {print $3}')     # e.g. 17A400
IFS=. read -r XCODE_MAJOR XCODE_MINOR XCODE_PATCH <<< "$XCODE_VERSION"
DTXCODE=$(printf "%02d%d%d" "$XCODE_MAJOR" "${XCODE_MINOR:-0}" "${XCODE_PATCH:-0}")  # 26.0.1 → 2601, as Xcode writes it
SDK_VERSION=$(xcrun --sdk macosx --show-sdk-version)
SDK_BUILD=$(xcrun --sdk macosx --show-sdk-build-version)
OS_BUILD=$(sw_vers -buildVersion)

plist_set() {
    /usr/libexec/PlistBuddy -c "Delete :$1" "$APP_INFO_PLIST" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$APP_INFO_PLIST"
}
plist_set BuildMachineOSBuild string "$OS_BUILD"
plist_set DTCompiler string com.apple.compilers.llvm.clang.1_0
plist_set DTPlatformBuild string "$SDK_BUILD"
plist_set DTPlatformName string macosx
plist_set DTPlatformVersion string "$SDK_VERSION"
plist_set DTSDKBuild string "$SDK_BUILD"
plist_set DTSDKName string "macosx${SDK_VERSION}"
plist_set DTXcode string "$DTXCODE"
plist_set DTXcodeBuild string "$XCODE_BUILD"
echo "   Xcode ${XCODE_VERSION} (${XCODE_BUILD}), macOS SDK ${SDK_VERSION} (${SDK_BUILD})"

echo "📜 Embedding provisioning profile..."
cp "$PROVISION_PROFILE" "${CONTENTS_DIR}/embedded.provisionprofile"

# One executable and no nested code, so the bundle signature covers everything —
# no --deep (Apple advises against it; it also spreads entitlements onto nested code).
echo "🔏 Signing app for Mac App Store with: ${APP_SIGN_IDENTITY}"
codesign --force --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$APP_SIGN_IDENTITY" \
    "$APP_BUNDLE"
codesign --verify --strict --verbose=2 "$APP_BUNDLE"

SIGNED_ENTITLEMENTS=$(codesign -d --entitlements - "$APP_BUNDLE" 2>/dev/null)
if [[ "$SIGNED_ENTITLEMENTS" != *"${TEAM_ID}.${BUNDLE_ID}"* ]]; then
    echo "❌ Signed entitlements are missing com.apple.application-identifier"
    exit 1
fi

echo "📦 Building installer package..."
mkdir -p "$DIST_DIR"
rm -f "$PKG_PATH"
productbuild --component "$APP_BUNDLE" /Applications \
    --sign "$INSTALLER_SIGN_IDENTITY" \
    "$PKG_PATH"
pkgutil --check-signature "$PKG_PATH"

echo "✨ MAS build complete"
echo "   Package: ${PKG_PATH}"
echo "   Version: ${VERSION} ($(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_INFO_PLIST"))"
echo ""
echo "👉 Next step: open Transporter.app, sign in, drag ${PKG_PATH} in, then Deliver."
echo "   Transporter validates the package before it uploads."
