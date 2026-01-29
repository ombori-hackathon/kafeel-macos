#!/usr/bin/env swift
import Foundation
import SwiftUI
import AppKit

// Import the icon views and generator
// Note: This script assumes it's run from the project root

/// Programmatically generated app icon for Kafeel
struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Modern gradient background - purple to blue
            LinearGradient(
                colors: [
                    Color(hex: "667eea"),
                    Color(hex: "764ba2")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Stylized activity chart
            VStack(spacing: 0) {
                Spacer()

                HStack(alignment: .bottom, spacing: size * 0.05) {
                    // Bar 1 - Short
                    RoundedRectangle(cornerRadius: size * 0.03)
                        .fill(.white)
                        .frame(width: size * 0.15, height: size * 0.25)

                    // Bar 2 - Tall (focus peak)
                    RoundedRectangle(cornerRadius: size * 0.03)
                        .fill(.white)
                        .frame(width: size * 0.15, height: size * 0.45)

                    // Bar 3 - Medium
                    RoundedRectangle(cornerRadius: size * 0.03)
                        .fill(.white.opacity(0.9))
                        .frame(width: size * 0.15, height: size * 0.35)

                    // Bar 4 - Growing
                    RoundedRectangle(cornerRadius: size * 0.03)
                        .fill(.white.opacity(0.85))
                        .frame(width: size * 0.15, height: size * 0.38)
                }

                Spacer()
                    .frame(height: size * 0.15)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum IconGeneratorError: Error {
    case renderFailed(size: Int)
    case cgImageConversionFailed
    case pngDataConversionFailed
}

func saveNSImageAsPNG(_ image: NSImage, to url: URL) throws {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        throw IconGeneratorError.cgImageConversionFailed
    }

    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        throw IconGeneratorError.pngDataConversionFailed
    }

    try pngData.write(to: url)
}

@MainActor
func generateAppIcons(outputDirectory: URL) throws {
    let sizes: [(size: Int, scale: Int)] = [
        (16, 1), (16, 2),
        (32, 1), (32, 2),
        (128, 1), (128, 2),
        (256, 1), (256, 2),
        (512, 1), (512, 2)
    ]

    print("Generating app icons to \(outputDirectory.path)...")

    for (size, scale) in sizes {
        let pixelSize = size * scale
        let iconView = AppIconView(size: CGFloat(pixelSize))

        let renderer = ImageRenderer(content: iconView)
        renderer.scale = 1.0 // We're already scaling in pixelSize

        guard let nsImage = renderer.nsImage else {
            throw IconGeneratorError.renderFailed(size: pixelSize)
        }

        let suffix = scale == 2 ? "@2x" : ""
        let filename = "icon_\(size)x\(size)\(suffix).png"
        let fileURL = outputDirectory.appendingPathComponent(filename)

        try saveNSImageAsPNG(nsImage, to: fileURL)
        print("  ✓ Generated: \(filename)")
    }
}

// Main execution
@MainActor
func main() async throws {
    let outputDirectory = URL(fileURLWithPath: "Resources/AppIcon.iconset")

    // Create directory if it doesn't exist
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    try generateAppIcons(outputDirectory: outputDirectory)

    print("\n✓ All icons generated successfully!")
    print("\nNext steps:")
    print("1. Run: iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns")
    print("2. Run: ./scripts/build-app.sh")
}

Task { @MainActor in
    do {
        try await main()
        exit(0)
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

dispatchMain()
