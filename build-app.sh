#!/bin/bash

set -euo pipefail

APP_NAME="Spellbreak"
BUILD_ROOT="build"
APP_BUNDLE="${BUILD_ROOT}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
INFO_PLIST="Sources/Spellbreak/Resources/Info.plist"
SOUNDS_DIR="Sources/Spellbreak/Resources/Sounds"
ICONSET_SOURCE="Assets.xcassets/AppIcon.appiconset"
ARM64_SCRATCH=".build-arm64"
X86_SCRATCH=".build-x86_64"
UNIVERSAL_BINARY="/tmp/${APP_NAME}-universal-$$"

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

cleanup() {
    rm -f "$UNIVERSAL_BINARY"
}
trap cleanup EXIT

build_arch() {
    local arch="$1"
    local scratch="$2"

    echo "📦 Building ${arch}..."
    swift build -c release --arch "$arch" --scratch-path "$scratch"
}

build_binaries=()

if build_arch arm64 "$ARM64_SCRATCH"; then
    build_binaries+=("${ARM64_SCRATCH}/release/${APP_NAME}")
else
    echo "⚠ arm64 build failed"
fi

if build_arch x86_64 "$X86_SCRATCH"; then
    build_binaries+=("${X86_SCRATCH}/release/${APP_NAME}")
else
    echo "⚠ x86_64 build failed, falling back to arm64-only output"
fi

if [[ ${#build_binaries[@]} -eq 0 ]]; then
    echo "Build failed for every architecture"
    exit 1
fi

echo "📁 Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

if [[ ${#build_binaries[@]} -gt 1 ]]; then
    echo "🧬 Creating universal binary..."
    lipo -create -output "$UNIVERSAL_BINARY" "${build_binaries[@]}"
    cp "$UNIVERSAL_BINARY" "${MACOS_DIR}/${APP_NAME}"
else
    cp "${build_binaries[0]}" "${MACOS_DIR}/${APP_NAME}"
fi

chmod +x "${MACOS_DIR}/${APP_NAME}"
cp "$INFO_PLIST" "${CONTENTS_DIR}/Info.plist"
cp -R "$SOUNDS_DIR" "${RESOURCES_DIR}/"

echo "🎨 Creating app icon..."
if command -v iconutil >/dev/null 2>&1 && [[ -d "$ICONSET_SOURCE" ]]; then
    ICONSET_DIR="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"
    cp "${ICONSET_SOURCE}"/icon_*.png "$ICONSET_DIR"/
    iconutil -c icns "$ICONSET_DIR" -o "${RESOURCES_DIR}/AppIcon.icns"
    rm -rf "$(dirname "$ICONSET_DIR")"
else
    echo "⚠ iconutil unavailable, app icon was not rebuilt"
fi

codesign --remove-signature "${MACOS_DIR}/${APP_NAME}" >/dev/null 2>&1 || true
codesign --remove-signature "$APP_BUNDLE" >/dev/null 2>&1 || true
xattr -cr "$APP_BUNDLE" >/dev/null 2>&1 || true

if [[ -n "$SIGN_IDENTITY" ]]; then
    echo "🔏 Signing app with: ${SIGN_IDENTITY}"
    codesign --deep --force --verify --verbose \
        --sign "$SIGN_IDENTITY" \
        --entitlements Spellbreak.entitlements \
        --options runtime \
        --timestamp \
        "$APP_BUNDLE"
    codesign --verify --verbose "$APP_BUNDLE"
else
    echo "⚠ Unsigned build ready"
fi

echo "✨ App build complete"
echo "   App: ${APP_BUNDLE}"
file "${MACOS_DIR}/${APP_NAME}"
