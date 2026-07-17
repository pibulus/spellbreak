#!/bin/bash

set -euo pipefail

APP_NAME="Spellbreak"
BUILD_ROOT="build"
APP_BUNDLE="${BUILD_ROOT}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
PROVISION_PROFILE="Spellbreak_MAS.provisionprofile"
ENTITLEMENTS="Spellbreak.entitlements"
DIST_DIR="dist"
PKG_PATH="${DIST_DIR}/${APP_NAME}-v1.0.0-mas.pkg"

APP_SIGN_IDENTITY="Apple Distribution: Pablo Alvarado (V433H655PN)"
INSTALLER_SIGN_IDENTITY="3rd Party Mac Developer Installer: Pablo Alvarado (V433H655PN)"

echo "📦 Building unsigned app via build-app.sh..."
./build-app.sh

if [[ ! -f "$PROVISION_PROFILE" ]]; then
    echo "❌ Missing provisioning profile: ${PROVISION_PROFILE}"
    echo "   Download an App Store distribution provisioning profile for"
    echo "   com.pabloalvarado.spellbreak from developer.apple.com, save it"
    echo "   as '${PROVISION_PROFILE}' in this directory, then re-run."
    exit 1
fi

echo "📜 Embedding provisioning profile..."
cp "$PROVISION_PROFILE" "${CONTENTS_DIR}/embedded.provisionprofile"

echo "🔏 Signing app for Mac App Store with: ${APP_SIGN_IDENTITY}"
codesign --deep --force --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$APP_SIGN_IDENTITY" \
    "$APP_BUNDLE"
codesign --verify --verbose "$APP_BUNDLE"

echo "📦 Building installer package..."
mkdir -p "$DIST_DIR"
productbuild --component "$APP_BUNDLE" /Applications \
    --sign "$INSTALLER_SIGN_IDENTITY" \
    "$PKG_PATH"

echo "✨ MAS build complete"
echo "   Package: ${PKG_PATH}"
echo ""
echo "👉 Next step: upload with Transporter.app, or run:"
echo "   xcrun altool --upload-app -f ${PKG_PATH} -t macos -u pibulus@gmail.com -p @keychain:AC_PASSWORD"
