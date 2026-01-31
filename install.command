#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_PATH="$SCRIPT_DIR/Orchard.xcodeproj"
SCHEME="Orchard"
CONFIGURATION="Release"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "error: $PROJECT_PATH not found" >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found (install Xcode or Command Line Tools)" >&2
  exit 1
fi

DERIVED_DATA="$(mktemp -d "${TMPDIR:-/tmp}/orchard-deriveddata.XXXXXX")"
cleanup() {
  rm -rf "$DERIVED_DATA"
}
trap cleanup EXIT

echo "Building $SCHEME ($CONFIGURATION)..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk macosx \
  -derivedDataPath "$DERIVED_DATA" \
  build

shopt -s nullglob
APP_CANDIDATES=("$DERIVED_DATA/Build/Products/${CONFIGURATION}"*/Orchard.app)
shopt -u nullglob

if [[ "${#APP_CANDIDATES[@]}" -eq 0 ]]; then
  echo "error: build finished but Orchard.app was not found" >&2
  exit 1
fi

APP_PATH="${APP_CANDIDATES[0]}"

DEST_DIR="$HOME/Applications"
DEST_APP="$DEST_DIR/Orchard.app"

echo "Installing to $DEST_APP..."
mkdir -p "$DEST_DIR"
rm -rf "$DEST_APP"
ditto "$APP_PATH" "$DEST_APP"

echo "Done."
