#!/bin/bash

# Build Spellbreak as a distributable DMG
# Usage: ./build-dmg.sh [--sign "Developer ID Application: Name"]

set -e

APP_NAME="Spellbreak"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-v${VERSION}"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
DMG_DIR="dist"

# Parse arguments
SIGN_IDENTITY=""
while [[ $# -gt 0 ]]; do
    case $1 in
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
echo ""

# Step 1: Build
echo "📦 Compiling Swift package (release, arm64)..."
swift build -c release --arch arm64
echo "   ✓ Build succeeded"

# Step 2: Create app bundle
echo "📁 Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy executable
cp .build/release/${APP_NAME} "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy Info.plist
cp Sources/Spellbreak/Resources/Info.plist "${CONTENTS_DIR}/"

# Copy sound resources
cp -r Sources/Spellbreak/Resources/Sounds "${RESOURCES_DIR}/"

# Compile icon asset catalog
echo "🎨 Compiling app icon..."
if command -v xcrun &> /dev/null && xcrun --find actool &> /dev/null; then
    xcrun actool Assets.xcassets \
        --compile "${RESOURCES_DIR}" \
        --platform macosx \
        --minimum-deployment-target 13.0 \
        --app-icon AppIcon \
        --output-partial-info-plist /dev/null 2>/dev/null || {
        echo "   ⚠ actool failed, copying icon manually..."
        # Fallback: create icns from largest PNG
        if [ -f "Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" ]; then
            ICONSET_DIR=$(mktemp -d)/AppIcon.iconset
            mkdir -p "${ICONSET_DIR}"
            for f in Assets.xcassets/AppIcon.appiconset/icon_*.png; do
                cp "$f" "${ICONSET_DIR}/$(basename "$f")"
            done
            iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/AppIcon.icns" 2>/dev/null || true
            rm -rf "$(dirname "${ICONSET_DIR}")"
        fi
    }
else
    echo "   ⚠ actool not found, creating icns from PNGs..."
    ICONSET_DIR=$(mktemp -d)/AppIcon.iconset
    mkdir -p "${ICONSET_DIR}"
    for f in Assets.xcassets/AppIcon.appiconset/icon_*.png; do
        cp "$f" "${ICONSET_DIR}/$(basename "$f")"
    done
    iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/AppIcon.icns" 2>/dev/null || true
    rm -rf "$(dirname "${ICONSET_DIR}")"
fi

# Add icon reference to Info.plist if not present
if ! grep -q "CFBundleIconFile" "${CONTENTS_DIR}/Info.plist"; then
    sed -i '' 's|</dict>|    <key>CFBundleIconFile</key>\
    <string>AppIcon</string>\
</dict>|' "${CONTENTS_DIR}/Info.plist"
fi

echo "   ✓ App bundle created"

# Step 3: Code sign if identity provided
if [ -n "$SIGN_IDENTITY" ]; then
    echo "🔏 Signing with: ${SIGN_IDENTITY}..."
    codesign --deep --force --verify --verbose \
        --sign "$SIGN_IDENTITY" \
        --entitlements Spellbreak.entitlements \
        --options runtime \
        --timestamp \
        "${APP_BUNDLE}"
    echo "   ✓ Signed and timestamped"
else
    echo "⚠  No signing identity provided (unsigned build)"
    echo "   Use --sign \"Developer ID Application: Name\" for signed builds"
fi

# Step 4: Create DMG
echo "💿 Creating DMG..."
mkdir -p "${DMG_DIR}"
rm -f "${DMG_DIR}/${DMG_NAME}.dmg"

# Create temporary DMG directory with app and Applications symlink
DMG_STAGING=$(mktemp -d)
cp -r "${APP_BUNDLE}" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${DMG_STAGING}" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "${DMG_DIR}/${DMG_NAME}.dmg"

rm -rf "${DMG_STAGING}"

# Sign the DMG too if identity provided
if [ -n "$SIGN_IDENTITY" ]; then
    echo "🔏 Signing DMG..."
    codesign --force --sign "$SIGN_IDENTITY" --timestamp "${DMG_DIR}/${DMG_NAME}.dmg"
    echo "   ✓ DMG signed"
fi

echo ""
echo "✨ Build complete!"
echo "   App: ${APP_BUNDLE}"
echo "   DMG: ${DMG_DIR}/${DMG_NAME}.dmg"
DMG_SIZE=$(du -h "${DMG_DIR}/${DMG_NAME}.dmg" | cut -f1 | tr -d ' ')
echo "   Size: ${DMG_SIZE}"

if [ -z "$SIGN_IDENTITY" ]; then
    echo ""
    echo "📝 To create a signed build:"
    echo "   ./build-dmg.sh --sign \"Developer ID Application: Your Name (TEAMID)\""
fi
