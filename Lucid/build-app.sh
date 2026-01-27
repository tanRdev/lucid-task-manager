#!/bin/bash
# Build script to create a proper macOS app bundle with icon

set -e

# Configuration
APP_NAME="Lucid"
BUILD_DIR=".build/arm64-apple-macosx/debug"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
EXECUTABLE="$BUILD_DIR/$APP_NAME"

echo "Building $APP_NAME.app bundle..."

# Clean previous build
rm -rf "$APP_BUNDLE"

# Create app bundle structure
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy executable
cp "$EXECUTABLE" "$MACOS/"

# Copy Info.plist
cp "Lucid/Info.plist" "$CONTENTS/Info.plist"

# Copy Assets.xcassets to Resources
cp -R "Lucid/Assets.xcassets" "$RESOURCES/"

# Create icon set from Assets.xcassets for macOS to recognize
ICONSET="$RESOURCES/AppIcon.iconset"
mkdir -p "$ICONSET"

# Copy icon files from Assets.xcassets to a location macOS recognizes
cp Lucid/Assets.xcassets/AppIcon.appiconset/icon_16x16.png "$ICONSET/icon_16x16.png"
cp Lucid/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png "$ICONSET/icon_16x16@2x.png"
cp Lucid/Assets.xcassets/AppIcon.appiconset/icon_32x32.png "$ICONSET/icon_32x32.png"
cp Lucid/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png "$ICONSET/icon_32x32@2x.png"
cp Lucid/Assets.xcassets/AppIcon.appiconset/icon_128x128.png "$ICONSET/icon_128x128.png"
cp Lucid/Assets.xcassets/AppIcon.appiconset/icon_256x256.png "$ICONSET/icon_256x256.png"
cp Lucid/Assets.xcassets/AppIcon.appiconset/icon_256x256.png "$ICONSET/icon_128x128@2x.png"
cp Lucid/Assets.xcassets/AppIcon.appiconset/icon_512x512.png "$ICONSET/icon_256x256@2x.png"
cp Lucid/Assets.xcassets/AppIcon.appiconset/icon_512x512.png "$ICONSET/icon_512x512.png"
cp Lucid/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png "$ICONSET/icon_512x512@2x.png"

# Create iconset Contents.json
cat > "$ICONSET/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_1024x1024.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# Update Info.plist to reference the icon
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$CONTENTS/Info.plist" 2>/dev/null || true

echo "✓ $APP_NAME.app bundle created successfully"
echo "  Location: $APP_BUNDLE"
