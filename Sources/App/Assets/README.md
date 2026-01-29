# Kafeel App Icons

## Icon Design

The Kafeel app icon features a modern activity chart design with a purple-blue gradient background.

### Components
- **AppIconView.swift** - SwiftUI view that renders the app icon programmatically
- **IconGenerator.swift** - Utility to export icon as PNG files at all required sizes
- **MenuBarIconView** - Simple monochrome version for menu bar

## Icon Design Concept

The icon shows a stylized bar chart representing activity tracking:
- 4 rounded bars of varying heights showing activity levels
- Purple to blue gradient background (hex: #667eea to #764ba2)
- Modern rounded corners following macOS design guidelines
- Clean white bars for maximum contrast and visibility

## Generating Icon Files

Once the project builds successfully, run:

```bash
swift run KafeelClient --generate-icons [output-directory]
```

This will generate all required macOS icon sizes:
- 16x16, 16x16@2x (32x32)
- 32x32, 32x32@2x (64x64)
- 128x128, 128x128@2x (256x256)
- 256x256, 256x256@2x (512x512)
- 512x512, 512x512@2x (1024x1024)

Plus a Contents.json file for Xcode Asset Catalog compatibility.

## Manual Generation

If the command-line generation doesn't work, you can:

1. Open the project in Xcode
2. Use the SwiftUI preview to render AppIconView at different sizes
3. Take screenshots and export as PNG
4. Or use a tool like ImageMagick to resize a single 1024x1024 render

## Using in Xcode Project

1. Create an Xcode project (File > New > Project)
2. Add Assets.xcassets to your project
3. Copy the generated AppIcon.appiconset folder into Assets.xcassets/
4. The icons will be automatically detected

## Menu Bar Icon

The MenuBarIconView provides a simple, template-style icon for the menu bar:
- 18x18 for standard resolution
- 36x36 for retina displays
- Monochrome design that adapts to light/dark mode
- Fallback SF Symbol: "chart.bar.fill"

## Preview

To preview the icons in Xcode, use the #Preview macros at the bottom of AppIconView.swift.
