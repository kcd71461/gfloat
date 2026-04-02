#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# Build .app bundle
bash scripts/bundle.sh

# Quit running instance
pkill -x GFloat 2>/dev/null && sleep 1 || true

# Install to /Applications
cp -R build/GFloat.app /Applications/GFloat.app

echo "Installed to /Applications/GFloat.app"
echo "Launching..."
open /Applications/GFloat.app
