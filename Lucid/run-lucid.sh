#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

./build-app.sh "${1:-debug}"
BIN_PATH="$(swift build --configuration "${1:-debug}" --show-bin-path)"
open "$BIN_PATH/Lucid.app"
