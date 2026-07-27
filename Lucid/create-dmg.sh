#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Lucid"
CONFIGURATION="${1:-release}"
VERSION="${2:-1.1.0}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: DMG builds are macOS-only." >&2
  exit 1
fi

if [[ "$CONFIGURATION" != "debug" && "$CONFIGURATION" != "release" ]]; then
  echo "Usage: $0 [debug|release] [version]" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="$ROOT_DIR/dist"
mkdir -p "$OUTPUT_DIR"

echo "Building universal $APP_NAME $VERSION ($CONFIGURATION)..."

BUILD_DIR="$ROOT_DIR/.build/universal"
ARM64_DIR="$BUILD_DIR/arm64"
X86_64_DIR="$BUILD_DIR/x86_64"

rm -rf "$BUILD_DIR"
mkdir -p "$ARM64_DIR" "$X86_64_DIR"

echo "  Building arm64..."
swift build --configuration "$CONFIGURATION" --arch arm64 --build-path "$ARM64_DIR"

echo "  Building x86_64..."
swift build --configuration "$CONFIGURATION" --arch x86_64 --build-path "$X86_64_DIR"

ARM64_BIN="$ARM64_DIR/$CONFIGURATION/$APP_NAME"
X86_64_BIN="$X86_64_DIR/$CONFIGURATION/$APP_NAME"

if [[ ! -f "$ARM64_BIN" ]]; then
  echo "Error: arm64 binary not found at $ARM64_BIN" >&2
  exit 1
fi

if [[ ! -f "$X86_64_BIN" ]]; then
  echo "Error: x86_64 binary not found at $X86_64_BIN" >&2
  exit 1
fi

UNIVERSAL_BIN="$BUILD_DIR/$APP_NAME"
lipo -create "$ARM64_BIN" "$X86_64_BIN" -output "$UNIVERSAL_BIN"

BIN_PATH="$BUILD_DIR"
EXECUTABLE="$UNIVERSAL_BIN"
APP_BUNDLE="$BIN_PATH/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ICONSET_SOURCE="Lucid/Assets.xcassets/AppIcon.appiconset"
ICONSET="$RESOURCES/AppIcon.iconset"
ENTITLEMENTS="Lucid/Lucid.entitlements"

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

cp "$EXECUTABLE" "$MACOS/$APP_NAME"
chmod +x "$MACOS/$APP_NAME"

PLIST="$CONTENTS/Info.plist"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>Lucid</string>
	<key>CFBundleIdentifier</key>
	<string>com.tan.lucid</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Lucid</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$VERSION</string>
	<key>CFBundleVersion</key>
	<string>$VERSION</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright © 2026. All rights reserved.</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
EOF

if [[ -d "$ICONSET_SOURCE" ]]; then
  cp -R "$ICONSET_SOURCE" "$ICONSET"
  if command -v iconutil >/dev/null 2>&1; then
    iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"
    rm -rf "$ICONSET"
  fi
  /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$PLIST"
fi

# Prefer Developer ID if available; otherwise ad-hoc for local/release CI artifacts.
SIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
CODESIGN_ARGS=(--force --deep --options runtime --sign "$SIGN_IDENTITY" --timestamp)
if [[ -f "$ENTITLEMENTS" ]]; then
  CODESIGN_ARGS+=(--entitlements "$ENTITLEMENTS")
fi

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  # Ad-hoc signatures do not support secure timestamping the same way.
  CODESIGN_ARGS=(--force --deep --sign - --timestamp=none)
  if [[ -f "$ENTITLEMENTS" ]]; then
    CODESIGN_ARGS+=(--entitlements "$ENTITLEMENTS")
  fi
  echo "Signing with ad-hoc identity (set CODESIGN_IDENTITY for Developer ID)..."
else
  echo "Signing with $SIGN_IDENTITY..."
fi

codesign "${CODESIGN_ARGS[@]}" "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

echo "Created $APP_BUNDLE"
echo "Binary architectures:"
lipo -info "$MACOS/$APP_NAME" || true

DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"
STAGING_DIR="$OUTPUT_DIR/staging"
RW_DMG="$OUTPUT_DIR/${APP_NAME}-rw.dmg"

rm -rf "$STAGING_DIR" "$RW_DMG" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

echo "Creating DMG at $DMG_PATH..."
hdiutil create \
  -volname "Lucid $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDRW \
  "$RW_DMG"

hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"
rm -f "$RW_DMG"
rm -rf "$STAGING_DIR"

# Optional notarization when credentials are present.
if [[ -n "${NOTARYTOOL_PROFILE:-}" ]]; then
  echo "Submitting DMG for notarization..."
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARYTOOL_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH" || true
  xcrun stapler staple "$APP_BUNDLE" || true
fi

echo "Created $DMG_PATH"
echo "DMG size: $(du -h "$DMG_PATH" | cut -f1)"
