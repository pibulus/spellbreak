#!/bin/bash

set -euo pipefail

APP_NAME="Spellbreak"
BUILD_ROOT="build"
APP_BUNDLE="${BUILD_ROOT}/${APP_NAME}.app"
INFO_PLIST="Sources/Spellbreak/Resources/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
DMG_NAME="${APP_NAME}-v${VERSION}"
DMG_DIR="dist"

SIGN_IDENTITY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sign)
            SIGN_IDENTITY="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo "🔮 Building ${APP_NAME} v${VERSION}..."

if [[ -n "$SIGN_IDENTITY" ]]; then
    ./build-app.sh --sign "$SIGN_IDENTITY"
else
    ./build-app.sh
fi

echo "💿 Creating DMG..."
mkdir -p "$DMG_DIR"
rm -f "${DMG_DIR}/${DMG_NAME}.dmg"

DMG_STAGING="$(mktemp -d)"
ditto "$APP_BUNDLE" "${DMG_STAGING}/${APP_NAME}.app"
ln -s /Applications "${DMG_STAGING}/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "${DMG_DIR}/${DMG_NAME}.dmg"

rm -rf "$DMG_STAGING"

if [[ -n "$SIGN_IDENTITY" ]]; then
    echo "🔏 Signing DMG..."
    codesign --force --sign "$SIGN_IDENTITY" --timestamp "${DMG_DIR}/${DMG_NAME}.dmg"
    codesign --verify --verbose "${DMG_DIR}/${DMG_NAME}.dmg"
else
    codesign --remove-signature "${DMG_DIR}/${DMG_NAME}.dmg" >/dev/null 2>&1 || true
fi

echo "✨ DMG build complete"
echo "   App: ${APP_BUNDLE}"
echo "   DMG: ${DMG_DIR}/${DMG_NAME}.dmg"
du -h "${DMG_DIR}/${DMG_NAME}.dmg" | awk '{print "   Size: " $1}'
