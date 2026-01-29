#!/bin/bash
set -e

echo "Building Kafeel.app..."

# Build the app in release mode
echo "Step 1: Building Swift package..."
swift build -c release

# Create app bundle structure
APP_NAME="Kafeel"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Step 2: Creating app bundle structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

# Copy executable
echo "Step 3: Copying executable..."
cp .build/release/KafeelClient "$MACOS/"

# Copy Info.plist
echo "Step 4: Copying Info.plist..."
cp Resources/Info.plist "$CONTENTS/"

# Copy icon (if it exists)
if [ -f Resources/AppIcon.icns ]; then
    echo "Step 5: Copying app icon..."
    cp Resources/AppIcon.icns "$RESOURCES/"
else
    echo "Step 5: Warning - AppIcon.icns not found, skipping icon copy"
    echo "         Run 'scripts/generate-icons.sh' to create icons first"
fi

echo ""
echo "✓ Successfully built $APP_BUNDLE"
echo ""
echo "To run the app:"
echo "  open $APP_BUNDLE"
echo ""
echo "To create a DMG:"
echo "  ./scripts/create-dmg.sh"
