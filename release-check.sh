#!/bin/bash

set -euo pipefail

APP_NAME="Spellbreak"
INFO_PLIST="Sources/Spellbreak/Resources/Info.plist"
APP_BUNDLE="build/${APP_NAME}.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
DMG_PATH="dist/${APP_NAME}-v${VERSION}.dmg"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

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

check_file "$APP_BUNDLE" "App bundle"
check_file "$DMG_PATH" "DMG"

if [[ -x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" ]]; then
    pass "App executable is present and executable"
else
    fail "App executable is missing or not executable"
fi

if /usr/bin/file "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" | grep -q "arm64"; then
    pass "App binary includes arm64"
else
    warn "App binary does not include arm64"
fi

if /usr/bin/file "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" | grep -q "x86_64"; then
    pass "App binary includes x86_64"
else
    warn "App binary does not include x86_64"
fi

if /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "${APP_BUNDLE}/Contents/Info.plist" | grep -q "com.pabloalvarado.spellbreak"; then
    pass "Bundle identifier is com.pabloalvarado.spellbreak"
else
    fail "Bundle identifier is not com.pabloalvarado.spellbreak"
fi

if /usr/libexec/PlistBuddy -c "Print :LSUIElement" "${APP_BUNDLE}/Contents/Info.plist" | grep -q "true"; then
    pass "App is configured as a menu bar accessory app"
else
    fail "LSUIElement is not enabled"
fi

if [[ -f "${APP_BUNDLE}/Contents/Resources/AppIcon.icns" ]]; then
    pass "App icon is bundled"
else
    fail "App icon is missing"
fi

if [[ -f "${APP_BUNDLE}/Contents/Resources/Sounds/ambient_loop.m4a" ]]; then
    pass "Ambient loop is bundled as compressed m4a"
else
    fail "Ambient loop m4a is missing"
fi

if codesign --verify --verbose "$APP_BUNDLE" >/tmp/spellbreak-codesign.log 2>&1; then
    pass "App code signature verifies"
else
    warn "App code signature does not verify"
    sed 's/^/   /' /tmp/spellbreak-codesign.log
fi

if codesign -dv --verbose=4 "$APP_BUNDLE" >/tmp/spellbreak-codesign-details.log 2>&1; then
    if grep -q "Authority=Developer ID Application" /tmp/spellbreak-codesign-details.log; then
        pass "App is signed with Developer ID Application"
    else
        warn "App is signed, but not with Developer ID Application"
    fi

    if grep -q "runtime" /tmp/spellbreak-codesign-details.log; then
        pass "Hardened runtime is enabled"
    else
        warn "Hardened runtime was not detected"
    fi
else
    warn "App signing details unavailable"
fi

if spctl -a -vvv -t execute "$APP_BUNDLE" >/tmp/spellbreak-spctl-app.log 2>&1; then
    pass "Gatekeeper accepts the app"
else
    warn "Gatekeeper does not accept the app yet"
    sed 's/^/   /' /tmp/spellbreak-spctl-app.log
fi

if [[ -f "$DMG_PATH" ]]; then
    if hdiutil imageinfo "$DMG_PATH" >/tmp/spellbreak-dmg-info.log 2>&1; then
        pass "DMG image is readable"
    else
        fail "DMG image is not readable"
        sed 's/^/   /' /tmp/spellbreak-dmg-info.log
    fi

    if xcrun stapler validate "$DMG_PATH" >/tmp/spellbreak-stapler.log 2>&1; then
        pass "DMG has a valid stapled notarization ticket"
    else
        warn "DMG does not have a stapled notarization ticket"
        sed 's/^/   /' /tmp/spellbreak-stapler.log
    fi

    if spctl -a -vvv -t open "$DMG_PATH" >/tmp/spellbreak-spctl-dmg.log 2>&1; then
        pass "Gatekeeper accepts the DMG"
    else
        warn "Gatekeeper does not accept the DMG yet"
        sed 's/^/   /' /tmp/spellbreak-spctl-dmg.log
    fi
fi

rm -f /tmp/spellbreak-codesign.log \
    /tmp/spellbreak-codesign-details.log \
    /tmp/spellbreak-spctl-app.log \
    /tmp/spellbreak-dmg-info.log \
    /tmp/spellbreak-stapler.log \
    /tmp/spellbreak-spctl-dmg.log

printf "\nRelease check: %d pass, %d warn, %d fail\n" "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
fi
