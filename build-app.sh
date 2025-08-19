#!/bin/bash

# Build script for Spellbreak
# Usage: ./build-app.sh [--sign "Developer ID"]

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

# Build the Swift package
echo "Building Spellbreak..."
swift build -c release --arch arm64

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Create app bundle structure
APP_NAME="Spellbreak"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean up existing app bundle
rm -rf "$APP_BUNDLE"

# Create directories
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp .build/release/Spellbreak "$MACOS_DIR/$APP_NAME"

# Copy Info.plist
cp Sources/Spellbreak/Resources/Info.plist "$CONTENTS_DIR/"

# Copy Resources
cp -r Sources/Spellbreak/Resources/Sounds "$RESOURCES_DIR/"
# Note: Assets.xcassets would need to be compiled with actool for production

# Make it executable
chmod +x "$MACOS_DIR/$APP_NAME"

# Code sign if identity provided
if [ -n "$SIGN_IDENTITY" ]; then
    echo "Signing app with identity: $SIGN_IDENTITY"
    codesign --deep --force --verify --verbose \
        --sign "$SIGN_IDENTITY" \
        --entitlements Spellbreak.entitlements \
        --options runtime \
        "$APP_BUNDLE"
    
    if [ $? -eq 0 ]; then
        echo "Successfully signed $APP_BUNDLE"
    else
        echo "Failed to sign app"
        exit 1
    fi
fi

echo "Build complete! You can now run: open $APP_BUNDLE"