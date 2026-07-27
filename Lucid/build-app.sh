#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Lucid"
CONFIGURATION="${1:-debug}"
VERSION="${2:-}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: $APP_NAME.app bundles can only be built on macOS." >&2
  exit 1
fi

if [[ "$CONFIGURATION" != "debug" && "$CONFIGURATION" != "release" ]]; then
  echo "Usage: $0 [debug|release] [version]" >&2
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
ENTITLEMENTS="Lucid/Lucid.entitlements"

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

if [[ -n "$VERSION" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$CONTENTS/Info.plist"
fi

# Copy SwiftPM resource bundle if present (Assets.xcassets packaged by SPM)
RESOURCE_BUNDLE="$(find "$BIN_PATH" -maxdepth 1 -name '*.bundle' -print -quit || true)"
if [[ -n "${RESOURCE_BUNDLE:-}" && -d "$RESOURCE_BUNDLE" ]]; then
  cp -R "$RESOURCE_BUNDLE" "$RESOURCES/"
fi

if [[ -d "$ICONSET_SOURCE" ]]; then
  cp -R "$ICONSET_SOURCE" "$ICONSET"

  if command -v iconutil >/dev/null 2>&1; then
    iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"
    rm -rf "$ICONSET"
  fi

  /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$CONTENTS/Info.plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$CONTENTS/Info.plist"
fi

# Re-sign the completed bundle so Info.plist and resources are bound into the signature.
CODESIGN_ARGS=(--force --deep --sign - --timestamp=none)
if [[ -f "$ENTITLEMENTS" ]]; then
  CODESIGN_ARGS+=(--entitlements "$ENTITLEMENTS")
fi
echo "Signing $APP_BUNDLE (ad-hoc)..."
codesign "${CODESIGN_ARGS[@]}" "$APP_BUNDLE"

echo "Verifying signature..."
codesign --verify --deep --strict "$APP_BUNDLE"
codesign -dv --verbose=2 "$APP_BUNDLE" 2>&1 | head -20

echo "✅ Created $APP_BUNDLE"
