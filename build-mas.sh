#!/bin/bash

set -euo pipefail

# --check-only runs the preflight and stops. It exists because the preflight
# is the whole answer to "what is missing for the App Store", and nobody should
# need a two-architecture release build to find that out.
CHECK_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --check-only) CHECK_ONLY=1 ;;
        -h|--help)
            echo "Usage: ./build-mas.sh [--check-only]"
            echo "  --check-only  run the preflight only, then exit"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            echo "Usage: ./build-mas.sh [--check-only]" >&2
            exit 2
            ;;
    esac
done

APP_NAME="Spellbreak"
# Stage the MAS bundle in build-mas/ so building a Mac App Store .pkg never
# overwrites the notarized Developer ID bundle at build/Spellbreak.app.
BUILD_ROOT="${BUILD_ROOT:-build-mas}"
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

# A team can legitimately hold more than one "Apple Distribution" certificate,
# and when it does, `codesign --sign "<name>"` fails with "ambiguous" — the
# build stops with two identical-looking identities. Signing by SHA-1 instead
# names exactly one certificate, and .asc-work/distribution.cer is the
# certificate the provisioning profile points at.
sign_identity_for() {
    local cert="$1" fallback="$2"
    if [[ -f "$cert" ]]; then
        local sha
        sha=$(openssl x509 -inform der -in "$cert" -fingerprint -sha1 -noout 2>/dev/null \
            | sed 's/.*=//; s/://g')
        if [[ -n "$sha" ]]; then
            echo "$sha"
            return
        fi
    fi
    echo "$fallback"
}

APP_SIGN_TARGET="$(sign_identity_for ".asc-work/distribution.cer" "$APP_SIGN_IDENTITY")"
INSTALLER_SIGN_TARGET="$(sign_identity_for ".asc-work/mac_installer_distribution.cer" "$INSTALLER_SIGN_IDENTITY")"

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

# Extract the exact SHA-1 certificate fingerprints embedded in the provisioning
# profile and verify at least one matching private-key identity is installed in
# the login keychain (checking by name alone passes on stale/revoked certs).
PROFILE_CERT_HASHES=$(python3 - "$PROFILE_PLIST" <<'PY'
import hashlib, plistlib, sys
with open(sys.argv[1], "rb") as fh:
    data = plistlib.load(fh)
print(" ".join(hashlib.sha1(c).hexdigest().upper() for c in data.get("DeveloperCertificates", [])))
PY
)
if [[ -z "$PROFILE_CERT_HASHES" ]]; then
    echo "❌ ${PROVISION_PROFILE} contains no DeveloperCertificates"
    exit 1
fi

INSTALLED_UPPER=$(echo "$INSTALLED_IDENTITIES" | tr '[:lower:]' '[:upper:]')
MATCHED_APP_HASH=""
for sha in $PROFILE_CERT_HASHES; do
    if [[ "$INSTALLED_UPPER" == *"$sha"* ]]; then
        MATCHED_APP_HASH="$sha"
        break
    fi
done
if [[ -z "$MATCHED_APP_HASH" ]]; then
    echo "❌ None of the distribution certificates inside ${PROVISION_PROFILE} (${PROFILE_CERT_HASHES}) are installed with a private key in your keychain."
    echo "   security find-identity -v   lists what's installed"
    echo "   If .asc-work/ holds the matching cert + key, import .asc-work/distribution.cer or re-run scripts/asc-provision.ts."
    exit 1
fi
APP_SIGN_TARGET="$MATCHED_APP_HASH"

if ! echo "$INSTALLED_IDENTITIES" | grep -Fq "$INSTALLER_SIGN_TARGET"; then
    echo "❌ Installer signing identity not in your keychain: ${INSTALLER_SIGN_TARGET}"
    echo "   security find-identity -v   lists what's installed"
    exit 1
fi

if [[ "$CHECK_ONLY" == "1" ]]; then
    echo "✅ Preflight passed — Xcode, profile (${MATCHED_APP_HASH}), and installer (${INSTALLER_SIGN_TARGET}) verified."
    echo "   Run ./build-mas.sh without --check-only to build dist/${APP_NAME}-v${VERSION}-mas.pkg"
    exit 0
fi

# --- Build ---

echo "📦 Building unsigned app via build-app.sh into ${BUILD_ROOT}/ (with the App Store unlock)..."
BUILD_ROOT="$BUILD_ROOT" SPELLBREAK_APP_STORE=1 ./build-app.sh

# The Mac App Store lists Spellbreak for Intel and Apple silicon. Keep an
# explicit architecture gate here even though build-app.sh already rejects
# x86_64 build failures by default.
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
    --sign "$APP_SIGN_TARGET" \
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
    --sign "$INSTALLER_SIGN_TARGET" \
    "$PKG_PATH"
pkgutil --check-signature "$PKG_PATH"

echo "MAS build complete"
echo "   Package: ${PKG_PATH}"
echo "   Version: ${VERSION} ($(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_INFO_PLIST"))"
echo ""
echo "👉 Next step: open Transporter.app, sign in, drag ${PKG_PATH} in, then Deliver."
echo "   Transporter validates the package before it uploads."
