#!/bin/bash
set -e

APP_NAME="Kafeel"
VERSION="1.0"
DMG_NAME="Kafeel-${VERSION}.dmg"
VOLUME_NAME="Kafeel ${VERSION}"

echo "Creating DMG installer for Kafeel..."

# First build the app
if [ ! -d "$APP_NAME.app" ]; then
    echo "Step 1: Building app bundle..."
    ./scripts/build-app.sh
else
    echo "Step 1: Using existing $APP_NAME.app"
fi

# Create temporary directory for DMG contents
echo "Step 2: Preparing DMG contents..."
TMP_DMG_DIR="dmg_tmp"
rm -rf "$TMP_DMG_DIR"
mkdir -p "$TMP_DMG_DIR"

# Copy app to temporary directory
cp -R "$APP_NAME.app" "$TMP_DMG_DIR/"

# Create Applications folder symlink
ln -s /Applications "$TMP_DMG_DIR/Applications"

# Create DMG
echo "Step 3: Creating disk image..."
rm -f "$DMG_NAME"

# Create a writable DMG first
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$TMP_DMG_DIR" \
    -ov -format UDRW \
    -fs HFS+ \
    temp.dmg

# Convert to compressed read-only DMG
hdiutil convert temp.dmg -format UDZO -o "$DMG_NAME"

# Clean up
rm -f temp.dmg
rm -rf "$TMP_DMG_DIR"

echo ""
echo "✓ Successfully created $DMG_NAME"
echo ""
echo "To distribute:"
echo "  1. Test: open $DMG_NAME"
echo "  2. Drag Kafeel.app to Applications"
echo "  3. Share the DMG file with users"
echo ""
echo "For code signing (optional):"
echo "  codesign --deep --force --sign 'Developer ID' $APP_NAME.app"
echo "  codesign --verify --verbose $APP_NAME.app"
