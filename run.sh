#!/bin/bash

# Kill any existing instance
pkill -f Spellbreak

# Build and create app bundle structure
swift build -c release

# Create app bundle
APP_NAME="Spellbreak"
BUNDLE_DIR="./build/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Clean and create directories
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy executable
cp .build/release/${APP_NAME} "${MACOS_DIR}/"

# Copy resources if they exist
if [ -d "Sources/Eyedrop/Resources/Assets.xcassets" ]; then
    cp -r Sources/Eyedrop/Resources/Assets.xcassets "${RESOURCES_DIR}/"
fi

# Copy sounds
if [ -d "Sources/Eyedrop/Resources/Sounds" ]; then
    cp -r Sources/Eyedrop/Resources/Sounds "${RESOURCES_DIR}/"
fi

# Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.pabloalvarado.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Launch the app
open "${BUNDLE_DIR}"