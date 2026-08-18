#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

swiftc \
    "$ROOT_DIR/Sources/Spellbreak/Utilities.swift" \
    "$ROOT_DIR/Tests/ScreenBusyCheck.swift" \
    -o "$BUILD_DIR/ScreenBusyCheck" \
    -target arm64-apple-macos13.0 \
    -framework SwiftUI \
    -framework AppKit \
    -parse-as-library

"$BUILD_DIR/ScreenBusyCheck"
