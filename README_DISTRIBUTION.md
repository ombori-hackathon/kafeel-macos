# Kafeel Distribution Guide

This guide explains how to build and distribute the Kafeel macOS app.

## Prerequisites

- macOS 14.0 or later
- Swift 6.0+ (included with Xcode)
- Command Line Tools for Xcode

## Quick Start

Build and distribute in one command:

```bash
# Generate icons and build app
./scripts/generate-icons.sh && ./scripts/build-app.sh

# Create DMG installer
./scripts/create-dmg.sh
```

## Step-by-Step Process

### 1. Generate App Icons

The app uses programmatically generated icons based on the design in `Sources/App/Assets/AppIconView.swift`.

```bash
# Generate all icon sizes and convert to .icns
./scripts/generate-icons.sh
```

This creates:
- `Resources/AppIcon.iconset/` - PNG files at all required sizes (16x16 to 512x512@2x)
- `Resources/AppIcon.icns` - macOS icon bundle for the app

**Icon Specifications:**
- Design: Purple-to-blue gradient with white bar chart
- Format: .icns (Apple Icon Image format)
- Sizes: 16x16, 32x32, 128x128, 256x256, 512x512 (1x and 2x)

### 2. Build the App Bundle

```bash
./scripts/build-app.sh
```

This script:
1. Compiles the Swift package in release mode
2. Creates `Kafeel.app` bundle structure
3. Copies the executable to `Contents/MacOS/`
4. Copies `Info.plist` to `Contents/`
5. Copies the app icon to `Contents/Resources/`

**Output:** `Kafeel.app` - A double-clickable macOS application

**Testing:**
```bash
open Kafeel.app
```

### 3. Create DMG Installer

```bash
./scripts/create-dmg.sh
```

This script:
1. Builds the app (if not already built)
2. Creates a temporary directory with the app and Applications symlink
3. Generates a compressed DMG file

**Output:** `Kafeel-1.0.dmg` - Installer for distribution

**Testing:**
```bash
open Kafeel-1.0.dmg
# Drag Kafeel.app to Applications folder
```

## File Structure

```
apps/macos-client/
├── Kafeel.app/                    # Built app bundle
│   └── Contents/
│       ├── Info.plist             # App metadata
│       ├── MacOS/
│       │   └── KafeelClient       # Executable
│       └── Resources/
│           └── AppIcon.icns       # App icon
│
├── Kafeel-1.0.dmg                 # DMG installer
│
├── Resources/
│   ├── AppIcon.iconset/           # PNG icons (all sizes)
│   ├── AppIcon.icns               # macOS icon bundle
│   └── Info.plist                 # Bundle metadata template
│
└── scripts/
    ├── generate-icons.sh          # Generate icons
    ├── build-app.sh               # Build app bundle
    └── create-dmg.sh              # Create DMG installer
```

## Distribution Checklist

- [ ] Update version number in `Resources/Info.plist`
- [ ] Update version in `scripts/create-dmg.sh`
- [ ] Generate fresh icons: `./scripts/generate-icons.sh`
- [ ] Build app bundle: `./scripts/build-app.sh`
- [ ] Test the app: `open Kafeel.app`
- [ ] Create DMG: `./scripts/create-dmg.sh`
- [ ] Test DMG installation
- [ ] (Optional) Code sign the app (see below)
- [ ] Distribute `Kafeel-1.0.dmg`

## Code Signing (Optional)

For wider distribution, you may want to sign the app with an Apple Developer certificate:

```bash
# Sign the app
codesign --deep --force --sign "Developer ID Application: Your Name (TEAM_ID)" Kafeel.app

# Verify signing
codesign --verify --verbose Kafeel.app
codesign --display --verbose=4 Kafeel.app

# Sign the DMG
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" Kafeel-1.0.dmg
```

**Note:** Without code signing, users will see a warning when first opening the app. They can bypass this by right-clicking the app and selecting "Open".

## Notarization (Optional)

For distribution outside the Mac App Store without warnings:

```bash
# Create a Developer ID signed app first (see above)

# Notarize
xcrun notarytool submit Kafeel-1.0.dmg \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# Staple the notarization ticket
xcrun stapler staple Kafeel-1.0.dmg
```

## Troubleshooting

### App shows default icon

**Problem:** The app uses a generic executable icon instead of the custom icon.

**Solution:**
1. Ensure `Resources/AppIcon.icns` exists
2. Rebuild the app: `./scripts/build-app.sh`
3. Clear icon cache: `rm -rf /var/folders/*/*/*/com.apple.iconservices*`
4. Restart Finder: `killall Finder`

### "Cannot be opened because the developer cannot be verified"

**Problem:** macOS blocks unsigned apps by default.

**Solution (for users):**
1. Right-click the app and select "Open"
2. Click "Open" in the security dialog

**Solution (for developers):**
- Sign the app with a Developer ID certificate (see Code Signing above)

### Icons look pixelated

**Problem:** Missing @2x (Retina) icon sizes.

**Solution:**
1. Verify all PNG files exist: `ls Resources/AppIcon.iconset/`
2. Should include both 1x and @2x versions
3. Regenerate if needed: `./scripts/generate-icons.sh`

## Customization

### Change App Icon

Edit the design in `Sources/App/Assets/AppIconView.swift`, then:

```bash
./scripts/generate-icons.sh
./scripts/build-app.sh
```

### Change App Metadata

Edit `Resources/Info.plist`:
- `CFBundleName` - App name
- `CFBundleVersion` - Build version
- `CFBundleShortVersionString` - Display version
- `CFBundleIdentifier` - Bundle ID (com.example.app)

### Change DMG Settings

Edit `scripts/create-dmg.sh`:
- `VERSION` - Version number
- `DMG_NAME` - Output filename
- `VOLUME_NAME` - DMG volume name

## Development Workflow

For regular development, use the Swift Package Manager commands:

```bash
# Run in debug mode (shows app window)
swift run KafeelClient

# Build only
swift build

# Run tests
swift test
```

Only use the distribution scripts when creating release builds or installers.

## Resources

- [Apple Bundle Documentation](https://developer.apple.com/documentation/bundleresources)
- [Info.plist Keys](https://developer.apple.com/documentation/bundleresources/information_property_list)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Notarization Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
