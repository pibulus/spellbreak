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
CHECK_TMP=$(mktemp -d)
DMG_MOUNT="${CHECK_TMP}/mounted-dmg"
cleanup() {
    if mount | grep -F " on ${DMG_MOUNT} (" >/dev/null; then
        hdiutil detach "$DMG_MOUNT" -quiet || return
    fi
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
    fail "App binary does not include arm64"
fi

if /usr/bin/file "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" | grep -q "x86_64"; then
    pass "App binary includes x86_64"
else
    fail "App binary does not include x86_64"
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

if codesign --verify --strict --verbose "$APP_BUNDLE" >"$CHECK_TMP/codesign.log" 2>&1; then
    pass "App code signature verifies"
else
    fail "App code signature does not verify"
    sed 's/^/   /' "$CHECK_TMP/codesign.log"
fi

if codesign -dv --verbose=4 "$APP_BUNDLE" >"$CHECK_TMP/codesign-details.log" 2>&1; then
    if grep -q "Authority=Developer ID Application" "$CHECK_TMP/codesign-details.log"; then
        pass "App is signed with Developer ID Application"
    else
        fail "App is not signed with Developer ID Application"
    fi

    if grep -q "runtime" "$CHECK_TMP/codesign-details.log"; then
        pass "Hardened runtime is enabled"
    else
        fail "Hardened runtime was not detected"
    fi
else
    fail "App signing details unavailable"
fi

if xcrun stapler validate "$APP_BUNDLE" >"$CHECK_TMP/stapler-app.log" 2>&1; then
    pass "App has a valid stapled notarization ticket"
else
    fail "App does not have a stapled notarization ticket"
    sed 's/^/   /' "$CHECK_TMP/stapler-app.log"
fi

if spctl -a -vvv -t execute "$APP_BUNDLE" >"$CHECK_TMP/spctl-app.log" 2>&1; then
    pass "Gatekeeper accepts the app"
else
    fail "Gatekeeper does not accept the app"
    sed 's/^/   /' "$CHECK_TMP/spctl-app.log"
fi

if [[ -f "$DMG_PATH" ]]; then
    if hdiutil imageinfo "$DMG_PATH" >"$CHECK_TMP/dmg-info.log" 2>&1; then
        pass "DMG image is readable"
    else
        fail "DMG image is not readable"
        sed 's/^/   /' "$CHECK_TMP/dmg-info.log"
    fi

    if xcrun stapler validate "$DMG_PATH" >"$CHECK_TMP/stapler-dmg.log" 2>&1; then
        pass "DMG has a valid stapled notarization ticket"
    else
        fail "DMG does not have a stapled notarization ticket"
        sed 's/^/   /' "$CHECK_TMP/stapler-dmg.log"
    fi

    # A valid old DMG beside a newly built app is not a valid new release.
    # Check the artifact inside the actual image, not just the staging bundle.
    mkdir -p "$DMG_MOUNT"
    if hdiutil attach "$DMG_PATH" -nobrowse -readonly -quiet -mountpoint "$DMG_MOUNT" >"$CHECK_TMP/mount.log" 2>&1; then
        INNER_APP="${DMG_MOUNT}/${APP_NAME}.app"
        if [[ -d "$INNER_APP" ]] && \
            cmp -s "${INNER_APP}/Contents/MacOS/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" && \
            cmp -s "${INNER_APP}/Contents/Info.plist" "${APP_BUNDLE}/Contents/Info.plist" && \
            cmp -s "${INNER_APP}/Contents/Resources/Sounds/ambient_loop.m4a" "${APP_BUNDLE}/Contents/Resources/Sounds/ambient_loop.m4a"; then
            pass "Packaged executable, version and ambient track match the built app"
        else
            fail "Packaged executable, version or ambient track differs from the built app"
        fi
        if xcrun stapler validate "$INNER_APP" >"$CHECK_TMP/stapler-inner.log" 2>&1 && \
            codesign --verify --strict "$INNER_APP" >"$CHECK_TMP/codesign-inner.log" 2>&1 && \
            spctl -a -vvv -t execute "$INNER_APP" >"$CHECK_TMP/spctl-inner.log" 2>&1; then
            pass "Packaged app is signed, stapled and accepted by Gatekeeper"
        else
            fail "Packaged app fails signature, stapling or Gatekeeper"
        fi
        hdiutil detach "$DMG_MOUNT" -quiet
    else
        fail "DMG does not mount"
        sed 's/^/   /' "$CHECK_TMP/mount.log"
    fi

    DMG_DOCTOR="$(command -v dmg-doctor || true)"
    if [[ -z "$DMG_DOCTOR" && -x "$HOME/.local/bin/dmg-doctor" ]]; then
        DMG_DOCTOR="$HOME/.local/bin/dmg-doctor"
    fi
    if [[ -n "$DMG_DOCTOR" ]]; then
        echo ""
        if "$DMG_DOCTOR" "$DMG_PATH"; then
            pass "dmg-doctor verified $DMG_PATH"
        else
            fail "dmg-doctor rejected $DMG_PATH"
        fi
    fi
fi

printf "\nRelease check: %d pass, %d warn, %d fail\n" "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
fi
