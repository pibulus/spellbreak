#!/bin/bash

set -euo pipefail

APP_NAME="Spellbreak"
BUILD_ROOT="build"
APP_BUNDLE="${BUILD_ROOT}/${APP_NAME}.app"
INFO_PLIST="Sources/Spellbreak/Resources/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
DMG_NAME="${APP_NAME}-v${VERSION}"
DMG_DIR="dist"
DMG_PATH="${DMG_DIR}/${DMG_NAME}.dmg"

SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-AC_PASSWORD}"
LOCAL_BUILD="${LOCAL_BUILD:-0}"

usage() {
    cat <<EOF
Usage: ./build-dmg.sh [--sign "Developer ID Application: Name (TEAMID)"] [--local]

Builds dist/Spellbreak-vVERSION.dmg. Auto-detects Developer ID Application
and notarizes + staples both Spellbreak.app and the DMG unless --local / LOCAL_BUILD=1.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sign)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "Missing value for --sign" >&2
                usage
                exit 2
            fi
            SIGN_IDENTITY="$2"
            shift 2
            ;;
        --local)
            LOCAL_BUILD=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 2
            ;;
    esac
done

if [[ -z "$SIGN_IDENTITY" && "$LOCAL_BUILD" != "1" ]]; then
    SIGN_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null \
        | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/' || true)
fi

echo "🔮 Building ${APP_NAME} v${VERSION}..."

if [[ -n "$SIGN_IDENTITY" ]]; then
    ./build-app.sh --sign "$SIGN_IDENTITY"
else
    ./build-app.sh
fi

# Notarize & staple the .app bundle BEFORE packing the DMG so the dragged app
# has its own offline ticket inside /Applications.
if [[ -n "$SIGN_IDENTITY" && "$LOCAL_BUILD" != "1" && "${SKIP_NOTARIZE:-0}" != "1" ]]; then
    if xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
        echo "🔐 Notarizing ${APP_BUNDLE} before packaging DMG (profile: ${NOTARY_PROFILE})..."
        APP_ZIP="${BUILD_ROOT}/${APP_NAME}-notarize.zip"
        ditto -c -k --keepParent "$APP_BUNDLE" "$APP_ZIP"
        xcrun notarytool submit "$APP_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
        rm -f "$APP_ZIP"
        xcrun stapler staple "$APP_BUNDLE"
        xcrun stapler validate "$APP_BUNDLE"
    else
        echo "⚠️  Notarization profile '${NOTARY_PROFILE}' unavailable or expired — checking if existing stapled ticket can be preserved..." >&2
    fi
fi

echo "💿 Creating DMG..."
mkdir -p "$DMG_DIR"
rm -f "$DMG_PATH"

prepare_dmg_stage() {
    local stage_dir="$1"
    rm -rf "$stage_dir"
    mkdir -p "$stage_dir"
    chmod 0755 "$stage_dir"
    ditto "$APP_BUNDLE" "${stage_dir}/${APP_NAME}.app"
    xcrun stapler staple "${stage_dir}/${APP_NAME}.app" >/dev/null 2>&1 || true
    chmod -R u+rwX,go+rX "$stage_dir"
    chmod 0755 "$stage_dir"
}

DMG_STAGING="$(mktemp -d)"
trap 'rm -rf "$DMG_STAGING"' EXIT
prepare_dmg_stage "$DMG_STAGING"

BG_TIFF="Sources/Spellbreak/Resources/dmg-background.tiff"
if command -v create-dmg >/dev/null 2>&1; then
    CREATE_DMG_ARGS=(
        --volname "$APP_NAME"
        --volicon "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
        --window-pos 200 120
        --window-size 660 428
        --text-size 13
        --icon-size 112
        --icon "${APP_NAME}.app" 165 190
        --hide-extension "${APP_NAME}.app"
        --app-drop-link 495 190
        --no-internet-enable
        --format UDZO
        --overwrite
    )
    if [[ -f "$BG_TIFF" ]]; then
        CREATE_DMG_ARGS+=(--background "$BG_TIFF")
    fi
    if ! create-dmg "${CREATE_DMG_ARGS[@]}" "$DMG_PATH" "$DMG_STAGING"; then
        rm -f "$DMG_PATH"
    fi
fi

if [[ ! -f "$DMG_PATH" ]]; then
    echo "💿 Fallback: Creating DMG with hdiutil..."
    prepare_dmg_stage "$DMG_STAGING"
    ln -s /Applications "${DMG_STAGING}/Applications"
    chmod 0755 "$DMG_STAGING"
    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$DMG_STAGING" \
        -ov \
        -format UDZO \
        -imagekey zlib-level=9 \
        "$DMG_PATH"
fi

if [[ -n "$SIGN_IDENTITY" ]]; then
    echo "🔏 Signing DMG..."
    codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG_PATH"
    codesign --verify --verbose "$DMG_PATH"
else
    codesign --remove-signature "$DMG_PATH" >/dev/null 2>&1 || true
fi

if [[ -n "$SIGN_IDENTITY" && "$LOCAL_BUILD" != "1" && "${SKIP_NOTARIZE:-0}" != "1" ]]; then
    if xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
        echo "🔐 Submitting DMG for notarization (profile: ${NOTARY_PROFILE})..."
        xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
        xcrun stapler staple "$DMG_PATH"
        xcrun stapler validate "$DMG_PATH"
    fi
fi

if [[ -x "$HOME/.claude/scripts/dev-tools/dmg-doctor" ]]; then
    if [[ "$LOCAL_BUILD" == "1" || "${SKIP_NOTARIZE:-0}" == "1" ]]; then
        "$HOME/.claude/scripts/dev-tools/dmg-doctor" "$DMG_PATH" --local
    else
        "$HOME/.claude/scripts/dev-tools/dmg-doctor" "$DMG_PATH"
    fi
fi

echo "✨ DMG build complete"
echo "   App: ${APP_BUNDLE}"
echo "   DMG: ${DMG_PATH}"
du -h "$DMG_PATH" | awk '{print "   Size: " $1}'
