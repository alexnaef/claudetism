#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="$PROJECT_ROOT/WindowTemplates"
BUILD_DIR="$PROJECT_ROOT/build"

APP_NAME="Window Templates"
BUNDLE_ID="com.alexnaef.WindowTemplates"
VERSION="${1:-0.1.0}"
EXECUTABLE_NAME="WindowTemplates"

echo "==> Building $APP_NAME v$VERSION"

# Clean previous build output
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build release binary
echo "==> Running swift build -c release"
cd "$PACKAGE_DIR"
swift build -c release

# Locate the compiled binary
BINARY="$PACKAGE_DIR/.build/release/$EXECUTABLE_NAME"
if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found at $BINARY"
    exit 1
fi

# Assemble .app bundle
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$BINARY" "$MACOS_DIR/$EXECUTABLE_NAME"

# Create Info.plist
cat > "$CONTENTS/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Window Templates</string>
    <key>CFBundleDisplayName</key>
    <string>Window Templates</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> App bundle assembled at $APP_BUNDLE"

# Ad-hoc codesign
echo "==> Code signing (ad-hoc)"
codesign --force --deep --sign - "$APP_BUNDLE"

# Verify codesign
codesign --verify --verbose "$APP_BUNDLE"
echo "==> Code signing verified"

# Create zip for distribution
ZIP_PATH="$BUILD_DIR/WindowTemplates.zip"
cd "$BUILD_DIR"
ditto -c -k --keepParent "$APP_NAME.app" "WindowTemplates.zip"
echo "==> Created $ZIP_PATH"

# Print SHA256 for Homebrew cask
SHA=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
echo ""
echo "========================================="
echo "  Build complete!"
echo "  App:  $APP_BUNDLE"
echo "  Zip:  $ZIP_PATH"
echo "  SHA256: $SHA"
echo "========================================="
