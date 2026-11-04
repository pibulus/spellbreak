#!/bin/bash

set -euo pipefail

APP_NAME="Spellbreak"
INFO_PLIST="Sources/Spellbreak/Resources/Info.plist"
BUILD_ROOT="${BUILD_ROOT:-build-mas}"
APP_BUNDLE="${BUILD_ROOT}/${APP_NAME}.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
PKG_PATH="dist/${APP_NAME}-v${VERSION}-mas.pkg"
TEAM_ID="V433H655PN"
BUNDLE_ID="com.pabloalvarado.spellbreak"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
CHECK_TMP=$(mktemp -d)
cleanup() {
    rm -rf "$CHECK_TMP"
}
trap cleanup EXIT

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf "✅ %s\n" "$1"
}

warn() {
    WARN_COUNT=$((WARN_COUNT + 1))
    printf "⚠️  %s\n" "$1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf "❌ %s\n" "$1"
}

check_file() {
    local path="$1"
    local label="$2"
    if [[ -e "$path" ]]; then
        pass "${label} exists: ${path}"
    else
        fail "${label} missing: ${path}"
    fi
}

check_file "$APP_BUNDLE" "MAS app bundle"
check_file "$PKG_PATH" "MAS installer package"

if [[ ! -d "$APP_BUNDLE" ]]; then
    printf "\nMAS check: %d pass, %d warn, %d fail\n" "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
    exit 1
fi

APP_BINARY="${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
APP_PLIST="${APP_BUNDLE}/Contents/Info.plist"
RESOURCES_DIR="${APP_BUNDLE}/Contents/Resources"
PRIVACY_PLIST="${RESOURCES_DIR}/PrivacyInfo.xcprivacy"
EMBEDDED_PROFILE="${APP_BUNDLE}/Contents/embedded.provisionprofile"

# 1. Binary & universal slices
if [[ -x "$APP_BINARY" ]]; then
    ARCHS=$(lipo -archs "$APP_BINARY" 2>/dev/null || true)
    if [[ "$ARCHS" == *arm64* && "$ARCHS" == *x86_64* ]]; then
        pass "Universal binary includes arm64 + x86_64 (${ARCHS})"
    else
        fail "Universal binary missing slice (got: ${ARCHS:-none})"
    fi
else
    fail "MAS executable missing or not executable"
fi

# 2. Info.plist lint + required MAS & Xcode toolchain keys
if plutil -lint "$APP_PLIST" >/dev/null 2>&1; then
    pass "Info.plist lints cleanly"
else
    fail "Info.plist fails plutil -lint"
fi

PLIST_OK=1
for key in CFBundleIdentifier CFBundleShortVersionString CFBundleVersion CFBundleIconName LSApplicationCategoryType LSMinimumSystemVersion DTXcode DTXcodeBuild DTSDKName DTSDKBuild DTPlatformName DTPlatformVersion DTPlatformBuild DTCompiler BuildMachineOSBuild; do
    if ! /usr/libexec/PlistBuddy -c "Print :${key}" "$APP_PLIST" >/dev/null 2>&1; then
        fail "Info.plist missing required key: ${key}"
        PLIST_OK=0
    fi
done
if [[ "$PLIST_OK" == "1" ]]; then
    pass "Info.plist carries all required MAS and Xcode DT* toolchain keys"
fi

ACTUAL_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PLIST" 2>/dev/null || true)
if [[ "$ACTUAL_BUNDLE_ID" == "$BUNDLE_ID" ]]; then
    pass "CFBundleIdentifier is ${BUNDLE_ID}"
else
    fail "CFBundleIdentifier is '${ACTUAL_BUNDLE_ID}', expected '${BUNDLE_ID}'"
fi

ICON_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconName" "$APP_PLIST" 2>/dev/null || true)
if [[ "$ICON_NAME" == "AppIcon" ]]; then
    pass "CFBundleIconName is AppIcon"
else
    fail "CFBundleIconName is '${ICON_NAME:-missing}', expected 'AppIcon'"
fi

# 3. Assets.car + AppIcon.icns 10-rep check
if [[ -s "${RESOURCES_DIR}/Assets.car" ]]; then
    pass "Compiled Assets.car is bundled ($(du -h "${RESOURCES_DIR}/Assets.car" | awk '{print $1}'))"
else
    fail "Assets.car is missing or empty (ITMS-90032 / ITMS-90713)"
fi

if [[ -f "${RESOURCES_DIR}/AppIcon.icns" ]]; then
    ICONSET_OUT="${CHECK_TMP}/AppIcon.iconset"
    if iconutil -c iconset "${RESOURCES_DIR}/AppIcon.icns" -o "$ICONSET_OUT" >/dev/null 2>&1; then
        REP_COUNT=$(ls "$ICONSET_OUT" | wc -l | tr -d ' ')
        if [[ "$REP_COUNT" -ge 10 ]]; then
            pass "AppIcon.icns contains all ${REP_COUNT} icon representations"
        else
            fail "AppIcon.icns has only ${REP_COUNT} representations (expected 10)"
        fi
    else
        fail "AppIcon.icns could not be unpacked by iconutil"
    fi
else
    fail "AppIcon.icns is missing"
fi

# 4. Privacy manifest (ITMS-91053)
if [[ -f "$PRIVACY_PLIST" ]] && plutil -lint "$PRIVACY_PLIST" >/dev/null 2>&1; then
    if grep -q "CA92.1" "$PRIVACY_PLIST" && grep -q "35F9.1" "$PRIVACY_PLIST"; then
        pass "PrivacyInfo.xcprivacy declares CA92.1 (UserDefaults) and 35F9.1 (SystemBootTime)"
    else
        fail "PrivacyInfo.xcprivacy missing CA92.1 or 35F9.1 required-reason API codes"
    fi
else
    fail "PrivacyInfo.xcprivacy missing or invalid"
fi

# 5. Bundled audio check
if [[ -s "${RESOURCES_DIR}/Sounds/ambient_loop.m4a" ]]; then
    pass "Bundled ambient_loop.m4a present"
else
    fail "Bundled ambient_loop.m4a missing"
fi

# 6. Embedded provisioning profile & leaf cert match
if [[ -f "$EMBEDDED_PROFILE" ]]; then
    PROFILE_PLIST="${CHECK_TMP}/profile.plist"
    security cms -D -i "$EMBEDDED_PROFILE" > "$PROFILE_PLIST"
    PROF_APP_ID=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:com.apple.application-identifier" "$PROFILE_PLIST" 2>/dev/null || true)
    if [[ "$PROF_APP_ID" == "${TEAM_ID}.${BUNDLE_ID}" ]] && ! /usr/libexec/PlistBuddy -c "Print :ProvisionedDevices" "$PROFILE_PLIST" >/dev/null 2>&1; then
        pass "embedded.provisionprofile is a Mac App Store distribution profile for ${PROF_APP_ID}"
    else
        fail "embedded.provisionprofile is invalid or lists ProvisionedDevices (${PROF_APP_ID})"
    fi

    codesign -d --extract-certificates="$CHECK_TMP/codesign_cert_" "$APP_BUNDLE" >/dev/null 2>&1 || true
    if [[ -f "$CHECK_TMP/codesign_cert_0" ]]; then
        LEAF_SHA1=$(openssl x509 -inform der -in "$CHECK_TMP/codesign_cert_0" -fingerprint -sha1 -noout | sed 's/.*=//; s/://g' | tr '[:lower:]' '[:upper:]')
        PROF_SHAS=$(python3 - "$PROFILE_PLIST" <<'PY'
import hashlib, plistlib, sys
with open(sys.argv[1], "rb") as fh:
    data = plistlib.load(fh)
print(" ".join(hashlib.sha1(c).hexdigest().upper() for c in data.get("DeveloperCertificates", [])))
PY
)
        if [[ " $PROF_SHAS " == *" $LEAF_SHA1 "* ]]; then
            pass "App signature leaf certificate (${LEAF_SHA1}) matches embedded.provisionprofile"
        else
            fail "App signature leaf (${LEAF_SHA1}) does NOT match embedded.provisionprofile (${PROF_SHAS})"
        fi
    else
        fail "Could not extract leaf certificate from signed MAS app"
    fi
else
    fail "embedded.provisionprofile missing from Contents/"
fi

# 7. Code signature & MAS sandbox entitlements
if codesign --verify --strict --verbose=2 "$APP_BUNDLE" >"$CHECK_TMP/codesign.log" 2>&1; then
    pass "MAS app code signature verifies strictly"
else
    fail "MAS app code signature failed verification"
    sed 's/^/   /' "$CHECK_TMP/codesign.log"
fi

ENTITLEMENTS_XML=$(codesign -d --entitlements :- "$APP_BUNDLE" 2>/dev/null || true)
if echo "$ENTITLEMENTS_XML" | grep -q "com.apple.security.app-sandbox" && \
   echo "$ENTITLEMENTS_XML" | grep -q "${TEAM_ID}.${BUNDLE_ID}" && \
   ! echo "$ENTITLEMENTS_XML" | grep -q "get-task-allow"; then
    pass "MAS entitlements carry App Sandbox + ${TEAM_ID}.${BUNDLE_ID} with no debug flags"
else
    fail "MAS entitlements invalid or contain get-task-allow"
fi

# 8. StoreKit compiled in & external purchase links excluded (Guideline 3.1.1 / 2.4.5(iv))
BIN_STRINGS="${CHECK_TMP}/bin.strings"
strings "$APP_BINARY" > "$BIN_STRINGS"
if grep -q "com.pabloalvarado.spellbreak.unlock" "$BIN_STRINGS" && grep -q "com.pabloalvarado.spellbreak.trial" "$BIN_STRINGS"; then
    pass "StoreKit IAP identifiers (.trial + .unlock) are compiled into MAS binary"
else
    fail "StoreKit IAP identifiers missing from MAS binary (-DAPP_STORE not active)"
fi

if ! grep -Eq "madebypablo\.app|github\.com/pibulus/spellbreak" "$BIN_STRINGS"; then
    pass "External purchase and direct-DMG GitHub URLs excluded from MAS binary"
else
    fail "MAS binary still contains external purchase or GitHub release URLs (Guideline 3.1.1)"
fi

# 9. Installer .pkg signature & payload byte-match
if [[ -f "$PKG_PATH" ]]; then
    if pkgutil --check-signature "$PKG_PATH" >"$CHECK_TMP/pkg-sig.log" 2>&1 && \
       grep -q "3rd Party Mac Developer Installer" "$CHECK_TMP/pkg-sig.log"; then
        pass "MAS .pkg signed with 3rd Party Mac Developer Installer"
    else
        fail "MAS .pkg signature check failed"
        sed 's/^/   /' "$CHECK_TMP/pkg-sig.log"
    fi

    EXPAND_DIR="${CHECK_TMP}/expanded-pkg"
    if pkgutil --expand-full "$PKG_PATH" "$EXPAND_DIR" >/dev/null 2>&1; then
        PKG_APP=$(find "$EXPAND_DIR" -maxdepth 3 -name "${APP_NAME}.app" -type d | head -n 1)
        if [[ -n "$PKG_APP" ]] && \
           cmp -s "${PKG_APP}/Contents/MacOS/${APP_NAME}" "$APP_BINARY" && \
           cmp -s "${PKG_APP}/Contents/Info.plist" "$APP_PLIST" && \
           cmp -s "${PKG_APP}/Contents/Resources/Assets.car" "${RESOURCES_DIR}/Assets.car"; then
            pass "Unpacked .pkg payload matches staged MAS app bundle byte-for-byte"
        else
            fail "Unpacked .pkg payload differs from staged MAS app bundle"
        fi
    else
        fail "pkgutil --expand-full failed on ${PKG_PATH}"
    fi
fi

printf "\nMAS check: %d pass, %d warn, %d fail\n" "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
fi
