#!/bin/bash
set -e

cd "$(dirname "$0")/.."

APP_NAME="GFloat"
BUNDLE_DIR="build/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Build release
swift build -c release

# Clean previous bundle
rm -rf "${BUNDLE_DIR}"

# Create bundle structure
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# Copy executable
cp .build/release/GFloat "${MACOS_DIR}/GFloat"

# Copy Info.plist
cp Resources/Info.plist "${CONTENTS_DIR}/Info.plist"

# Copy app icon
cp Resources/AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"

# Copy menu bar icons
cp Resources/MenuBarIcon/menubar-icon.png "${RESOURCES_DIR}/menubar-icon.png"
cp Resources/MenuBarIcon/menubar-icon@2x.png "${RESOURCES_DIR}/menubar-icon@2x.png"

echo "Built: ${BUNDLE_DIR}"
echo "Run: open \"${BUNDLE_DIR}\""
