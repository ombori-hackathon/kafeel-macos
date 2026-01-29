import SwiftUI
import AppKit

/// Utility to generate PNG icon files from SwiftUI views
public enum IconGenerator {
    /// Generate all required icon sizes for macOS app
    @MainActor
    public static func generateAppIcons(outputDirectory: URL) throws {
        let sizes: [(size: Int, scale: Int)] = [
            (16, 1), (16, 2),
            (32, 1), (32, 2),
            (128, 1), (128, 2),
            (256, 1), (256, 2),
            (512, 1), (512, 2)
        ]

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
            print("Generated: \(filename)")
        }
    }

    /// Save NSImage as PNG file
    private static func saveNSImageAsPNG(_ image: NSImage, to url: URL) throws {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw IconGeneratorError.cgImageConversionFailed
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw IconGeneratorError.pngDataConversionFailed
        }

        try pngData.write(to: url)
    }

    enum IconGeneratorError: Error, LocalizedError {
        case renderFailed(size: Int)
        case cgImageConversionFailed
        case pngDataConversionFailed

        var errorDescription: String? {
            switch self {
            case .renderFailed(let size):
                return "Failed to render icon at size \(size)x\(size)"
            case .cgImageConversionFailed:
                return "Failed to convert NSImage to CGImage"
            case .pngDataConversionFailed:
                return "Failed to convert bitmap to PNG data"
            }
        }
    }
}
