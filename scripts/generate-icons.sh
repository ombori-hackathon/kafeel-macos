#!/bin/bash
set -e

echo "Generating Kafeel app icons..."

# Navigate to project root
cd "$(dirname "$0")/.."

# Run the icon generator using the app
echo "Step 1: Generating PNG icons..."
swift run KafeelClient --generate-icons

# Check if icons were generated
if [ ! -f "Resources/AppIcon.iconset/icon_512x512@2x.png" ]; then
    echo "Error: Icons not generated properly"
    exit 1
fi

# Convert to .icns format
echo "Step 2: Converting to .icns format..."
iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns

echo ""
echo "✓ Icon generation complete!"
echo ""
echo "Generated files:"
ls -lh Resources/AppIcon.iconset/*.png | awk '{print "  " $9 " (" $5 ")"}'
echo ""
ls -lh Resources/AppIcon.icns | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "Next step: Run ./scripts/build-app.sh to create Kafeel.app"
