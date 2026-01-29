import SwiftUI

/// Modern design system for Kafeel - inspired by Linear, Raycast, and Arc
enum AppTheme {
    // MARK: - Colors

    static let background = Color(.windowBackgroundColor)
    static let cardBackground = Color(.controlBackgroundColor)
    static let surfaceBackground = Color(nsColor: .controlBackgroundColor)

    // Accent colors
    static let accent = Color.blue
    static let accentGradient = LinearGradient(
        colors: [Color.blue, Color.blue.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Status colors
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let info = Color.blue

    // Semantic colors
    static let productive = Color.green
    static let neutral = Color.gray
    static let distracting = Color.red

    // Text colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color(nsColor: .tertiaryLabelColor)

    // MARK: - Spacing

    static let spacing1: CGFloat = 4
    static let spacing2: CGFloat = 8
    static let spacing3: CGFloat = 12
    static let spacing4: CGFloat = 16
    static let spacing5: CGFloat = 20
    static let spacing6: CGFloat = 24
    static let spacing8: CGFloat = 32
    static let spacing10: CGFloat = 40

    // MARK: - Sizing

    static let cornerRadius: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 8

    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24

    // MARK: - Shadows

    static let cardShadow = Shadow(
        color: .black.opacity(0.08),
        radius: 12,
        x: 0,
        y: 4
    )

    static let hoverShadow = Shadow(
        color: .black.opacity(0.12),
        radius: 16,
        x: 0,
        y: 6
    )

    // MARK: - Animations

    static let animationFast = Animation.easeOut(duration: 0.15)
    static let animationNormal = Animation.easeOut(duration: 0.25)
    static let animationSlow = Animation.easeOut(duration: 0.35)
    static let animationSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)

    // MARK: - Blur Materials

    static let glassMaterial = Material.ultraThinMaterial
    static let cardMaterial = Material.regular
}

// MARK: - Shadow Helper

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions

extension View {
    /// Apply modern card styling with glass morphism effect
    func modernCard(padding: CGFloat = AppTheme.cardPadding) -> some View {
        self
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(
                color: AppTheme.cardShadow.color,
                radius: AppTheme.cardShadow.radius,
                x: AppTheme.cardShadow.x,
                y: AppTheme.cardShadow.y
            )
    }

    /// Apply hover scale effect
    @ViewBuilder
    func hoverEffect(scale: CGFloat = 1.02) -> some View {
        self.modifier(HoverScaleModifier(scale: scale))
    }

    /// Apply press scale effect
    func pressEffect() -> some View {
        self.modifier(PressScaleModifier())
    }
}

// MARK: - Hover Scale Modifier

struct HoverScaleModifier: ViewModifier {
    let scale: CGFloat
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? scale : 1.0)
            .animation(AppTheme.animationSpring, value: isHovering)
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

// MARK: - Press Scale Modifier

struct PressScaleModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AppTheme.animationFast, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Modern Card Wrapper Component

struct ModernCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let showBorder: Bool

    init(
        padding: CGFloat = AppTheme.cardPadding,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.showBorder = showBorder
    }

    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous))
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    }
                }
            )
            .shadow(
                color: AppTheme.cardShadow.color,
                radius: AppTheme.cardShadow.radius,
                x: AppTheme.cardShadow.x,
                y: AppTheme.cardShadow.y
            )
    }
}

// MARK: - Gradient Background Helper

extension Color {
    func gradient(to color: Color, startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(
            colors: [self, color],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}
