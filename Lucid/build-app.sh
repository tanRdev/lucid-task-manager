#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Lucid"
CONFIGURATION="${1:-debug}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: $APP_NAME.app bundles can only be built on macOS." >&2
  exit 1
fi

if [[ "$CONFIGURATION" != "debug" && "$CONFIGURATION" != "release" ]]; then
  echo "Usage: $0 [debug|release]" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "Building $APP_NAME ($CONFIGURATION)..."
swift build --configuration "$CONFIGURATION"

BIN_PATH="$(swift build --configuration "$CONFIGURATION" --show-bin-path)"
EXECUTABLE="$BIN_PATH/$APP_NAME"
APP_BUNDLE="$BIN_PATH/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ICONSET_SOURCE="Lucid/Assets.xcassets/AppIcon.appiconset"
ICONSET="$RESOURCES/AppIcon.iconset"

if [[ ! -f "$EXECUTABLE" ]]; then
  echo "Error: compiled executable not found at $EXECUTABLE" >&2
  exit 1
fi

echo "Creating app bundle at: $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

cp "$EXECUTABLE" "$MACOS/$APP_NAME"
chmod +x "$MACOS/$APP_NAME"
cp "Lucid/Info.plist" "$CONTENTS/Info.plist"

if [[ -d "$ICONSET_SOURCE" ]]; then
  cp -R "$ICONSET_SOURCE" "$ICONSET"

  if command -v iconutil >/dev/null 2>&1; then
    iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"
  fi

  /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$CONTENTS/Info.plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$CONTENTS/Info.plist"
fi

echo "✅ Created $APP_BUNDLE"
