#!/bin/bash
set -e

APP_NAME="Lucid"
BUILD_DIR=".build/arm64-apple-macosx/debug"
BUNDLE_DIR="$BUILD_DIR/$APP_NAME.app"

# Clean old bundle
rm -rf "$BUNDLE_DIR"

# Create app bundle structure
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$APP_NAME/Info.plist" "$BUNDLE_DIR/Contents/Info.plist"

# Set executable permissions
chmod +x "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"

echo "App bundle created at: $BUNDLE_DIR"
