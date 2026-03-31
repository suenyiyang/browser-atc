#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_NAME="BrowserATC"
APP_BUNDLE="$PROJECT_DIR/build/${APP_NAME}.app"

echo "Assembling ${APP_NAME}.app bundle..."

# Clean previous bundle
rm -rf "$APP_BUNDLE"

# Create bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Ad-hoc code sign (required for default browser registration)
codesign --force --sign - "$APP_BUNDLE"

echo "Bundle created and signed at: $APP_BUNDLE"
