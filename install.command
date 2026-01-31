#!/bin/bash

set -euo pipefail

# Orchard Installer Script
# Usage: ./install.command [--open]
# Example: ./install.command --open (to install and open the app)
#          ./install.command (to just install the app)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
OPEN_AFTER_INSTALL=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --open)
            OPEN_AFTER_INSTALL=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 [--open]"
            exit 1
            ;;
    esac
done

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

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

print_info "Building $SCHEME ($CONFIGURATION)..."

DERIVED_DATA="$(mktemp -d "${TMPDIR:-/tmp}/orchard-deriveddata.XXXXXX")"
cleanup() {
  rm -rf "$DERIVED_DATA"
}
trap cleanup EXIT

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

# Define destination in Applications folder
DEST_DIR="/Applications"
FINAL_APP_PATH="$DEST_DIR/Orchard.app"

# Check if the application is already installed
if [[ -d "$FINAL_APP_PATH" ]]; then
    print_warning "Orchard is already installed. Removing existing installation..."
    rm -rf "$FINAL_APP_PATH"
fi

print_info "Installing to $FINAL_APP_PATH..."
mkdir -p "$DEST_DIR"
rm -rf "$FINAL_APP_PATH"
ditto "$APP_PATH" "$FINAL_APP_PATH"

# Check if we should open the application after installation
if [[ "$OPEN_AFTER_INSTALL" == true ]]; then
    print_info "Opening Orchard application..."
    open "$FINAL_APP_PATH"

    if [[ $? -eq 0 ]]; then
        print_success "Orchard application launched successfully"
    else
        print_error "Failed to open Orchard application"
        exit 1
    fi
else
    print_info "Installation complete. Run 'open $FINAL_APP_PATH' to launch the application."
fi

print_success "Installation process completed!"