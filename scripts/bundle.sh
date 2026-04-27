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

# Stamp the version. Prefer $APP_VERSION (set by CI from the git tag), fall back to the
# nearest tag for local builds, and finally to a "0.0.0-dev" placeholder so the in-app
# update checker treats local dev builds as older than any release.
VERSION="${APP_VERSION:-}"
if [ -z "$VERSION" ]; then
    if VERSION_FROM_GIT="$(git -C "$PROJECT_DIR" describe --tags --abbrev=0 2>/dev/null)"; then
        VERSION="${VERSION_FROM_GIT#v}"
    else
        VERSION="0.0.0-dev"
    fi
fi
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_BUNDLE/Contents/Info.plist"
echo "Stamped bundle version: $VERSION"

# Copy app icon
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Ad-hoc code sign (required for default browser registration)
codesign --force --sign - "$APP_BUNDLE"

echo "Bundle created and signed at: $APP_BUNDLE"
