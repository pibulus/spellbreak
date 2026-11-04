#!/bin/bash

set -euo pipefail

APP_NAME="Spellbreak"
BUILD_ROOT="${BUILD_ROOT:-build}"
APP_BUNDLE="${BUILD_ROOT}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
INFO_PLIST="Sources/Spellbreak/Resources/Info.plist"
SOUNDS_DIR="Sources/Spellbreak/Resources/Sounds"
ASSETS_CATALOG="Sources/Spellbreak/Resources/Assets.xcassets"
ICONSET_SOURCE="${ASSETS_CATALOG}/AppIcon.appiconset"
# SPELLBREAK_APP_STORE=1 (set by build-mas.sh) compiles in the App Store unlock
# (Store.swift, -DAPP_STORE). Website builds leave it out and are never locked.
# Separate scratch dirs so the two never reuse each other's objects.
SWIFT_FLAGS=""
SCRATCH_SUFFIX=""
if [[ "${SPELLBREAK_APP_STORE:-0}" == "1" ]]; then
    SWIFT_FLAGS="-Xswiftc -DAPP_STORE"
    SCRATCH_SUFFIX="-appstore"
fi
ARM64_SCRATCH=".build-arm64${SCRATCH_SUFFIX}"
X86_SCRATCH=".build-x86_64${SCRATCH_SUFFIX}"
UNIVERSAL_BINARY="/tmp/${APP_NAME}-universal-$$"

SIGN_IDENTITY=""

usage() {
    cat <<EOF
Usage: ./build-app.sh [--sign "Developer ID Application: Name (TEAMID)"]

Builds build/Spellbreak.app as a universal app when both arm64 and x86_64
release builds are available. Without --sign, the app is unsigned for local
testing only.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sign)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "Missing value for --sign"
                usage
                exit 2
            fi
            SIGN_IDENTITY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 2
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
    # SWIFT_FLAGS is unquoted on purpose: "-Xswiftc -DAPP_STORE" is two arguments,
    # and an empty string must expand to none (bash 3.2 + set -u rules out an array)
    # shellcheck disable=SC2086
    swift build -c release --arch "$arch" --scratch-path "$scratch" $SWIFT_FLAGS
}

build_binaries=()

if build_arch arm64 "$ARM64_SCRATCH"; then
    build_binaries+=("${ARM64_SCRATCH}/release/${APP_NAME}")
else
    echo "❌ arm64 build failed" >&2
    exit 1
fi

if [[ "${UNIVERSAL:-1}" == "1" ]]; then
    if build_arch x86_64 "$X86_SCRATCH"; then
        build_binaries+=("${X86_SCRATCH}/release/${APP_NAME}")
    else
        echo "❌ x86_64 build failed (refusing to silently ship an arm64-only binary; set UNIVERSAL=0 only for local debug)" >&2
        exit 1
    fi
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

AUTO_BUILD_VERSION=$(date +%Y%m%d%H%M%S)
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${AUTO_BUILD_VERSION}" "${CONTENTS_DIR}/Info.plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${AUTO_BUILD_VERSION}" "${CONTENTS_DIR}/Info.plist"
cp -R "$SOUNDS_DIR" "${RESOURCES_DIR}/"
cp "Sources/Spellbreak/Resources/PrivacyInfo.xcprivacy" "${RESOURCES_DIR}/"

echo "🎨 Compiling asset catalog and app icon..."
if xcrun --find actool >/dev/null 2>&1 && [[ -d "$ASSETS_CATALOG" ]]; then
    ASSET_PLIST="$(mktemp)"
    xcrun actool --compile "$RESOURCES_DIR" \
        --platform macosx \
        --minimum-deployment-target 13.0 \
        --app-icon AppIcon \
        --output-partial-info-plist "$ASSET_PLIST" \
        "$ASSETS_CATALOG" >/dev/null
    /usr/libexec/PlistBuddy -x -c "Merge ${ASSET_PLIST}" "${CONTENTS_DIR}/Info.plist" >/dev/null 2>&1 || true
    rm -f "$ASSET_PLIST"
else
    echo "❌ xcrun actool unavailable — cannot compile Assets.car" >&2
    exit 1
fi

# actool puts all high-res reps into Assets.car and writes only 4 fallback sizes
# into AppIcon.icns. Rebuild AppIcon.icns directly via iconutil afterwards so
# both Assets.car AND a complete 10-representation AppIcon.icns ship together.
if command -v iconutil >/dev/null 2>&1 && [[ -d "$ICONSET_SOURCE" ]]; then
    ICONSET_DIR="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"
    cp "${ICONSET_SOURCE}"/icon_*.png "$ICONSET_DIR"/
    iconutil -c icns "$ICONSET_DIR" -o "${RESOURCES_DIR}/AppIcon.icns"
    rm -rf "$(dirname "$ICONSET_DIR")"
    # macOS ImageIO injects synthetic eXIf chunks when iconutil repacks PNG slots;
    # strip non-image metadata chunks so AppIcon.icns ships with pure PNG streams.
    python3 - "${RESOURCES_DIR}/AppIcon.icns" <<'PY'
import pathlib, struct, sys
p = pathlib.Path(sys.argv[1])
icns = p.read_bytes()
if icns[:4] == b"icns":
    drop = {b"tEXt", b"zTXt", b"iTXt", b"eXIf", b"tIME"}
    slots, pos = bytearray(), 8
    while pos < len(icns):
        ostype = icns[pos:pos+4]
        length = struct.unpack(">I", icns[pos+4:pos+8])[0]
        payload = icns[pos+8:pos+length]
        if payload.startswith(b"\x89PNG\r\n\x1a\n"):
            out, q = bytearray(b"\x89PNG\r\n\x1a\n"), 8
            while q < len(payload):
                clen = struct.unpack(">I", payload[q:q+4])[0]
                ctype = payload[q+4:q+8]
                if ctype not in drop:
                    out.extend(payload[q:q+12+clen])
                q += 12 + clen
                if ctype == b"IEND":
                    break
            payload = bytes(out)
        slots.extend(ostype + struct.pack(">I", 8 + len(payload)) + payload)
        pos += length
    p.write_bytes(b"icns" + struct.pack(">I", 8 + len(slots)) + bytes(slots))
PY
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
    # Apple Silicon refuses to spawn unsigned arm64 code (errno 163). lipo strips
    # the linker's ad-hoc signature, so a universal build MUST be re-signed even
    # when no Developer ID is supplied.
    echo "🔏 Ad-hoc signing (no Developer ID supplied)"
    codesign --force --deep --sign - "$APP_BUNDLE"
    codesign --verify "$APP_BUNDLE"
    echo "⚠ Unsigned build ready (ad-hoc only — not distributable)"
fi

echo "App build complete"
echo "   App: ${APP_BUNDLE}"
file "${MACOS_DIR}/${APP_NAME}"
