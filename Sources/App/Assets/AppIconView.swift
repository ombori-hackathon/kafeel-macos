import SwiftUI

/// Programmatically generated app icon for Kafeel
/// A modern activity tracker icon featuring a stylized chart/graph with gradient background
public struct AppIconView: View {
    let size: CGFloat

    public init(size: CGFloat = 1024) {
        self.size = size
    }

    public var body: some View {
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

/// Menu bar icon - simple and monochrome
public struct MenuBarIconView: View {
    let size: CGFloat

    public init(size: CGFloat = 18) {
        self.size = size
    }

    public var body: some View {
        // Simple chart icon for menu bar
        HStack(alignment: .bottom, spacing: 2) {
            RoundedRectangle(cornerRadius: 1)
                .fill(.primary)
                .frame(width: 3, height: size * 0.4)

            RoundedRectangle(cornerRadius: 1)
                .fill(.primary)
                .frame(width: 3, height: size * 0.7)

            RoundedRectangle(cornerRadius: 1)
                .fill(.primary)
                .frame(width: 3, height: size * 0.55)
        }
        .frame(width: size, height: size)
    }
}

/// Helper extension for hex color codes
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

/// Preview provider for icon development
#Preview("App Icon - 1024x1024") {
    AppIconView(size: 1024)
        .frame(width: 200, height: 200)
}

#Preview("App Icon - Small") {
    AppIconView(size: 128)
        .frame(width: 128, height: 128)
}

#Preview("Menu Bar Icon") {
    MenuBarIconView(size: 18)
        .padding()
        .background(Color.gray.opacity(0.2))
}
