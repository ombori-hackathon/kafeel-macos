import SwiftUI
import KafeelCore

struct StatsCardsView: View {
    let stats: [AppUsageStat]
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    @Binding var selectedCard: StatCardType?

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            StatCard(
                type: .screenTime,
                value: totalScreenTime,
                trend: 0.12,
                icon: "desktopcomputer"
            ) {
                selectedCard = .screenTime
            }

            StatCard(
                type: .productiveTime,
                value: productiveTime,
                trend: 0.08,
                icon: "checkmark.circle.fill"
            ) {
                selectedCard = .productiveTime
            }

            StatCard(
                type: .distractedTime,
                value: distractedTime,
                trend: -0.05,
                icon: "exclamationmark.triangle.fill"
            ) {
                selectedCard = .distractedTime
            }

            StatCard(
                type: .mostUsedApp,
                value: mostUsedAppName,
                trend: nil,
                icon: "app.fill"
            ) {
                selectedCard = .mostUsedApp
            }

            StatCard(
                type: .appSwitches,
                value: "\(appSwitches)",
                trend: -0.15,
                icon: "arrow.left.arrow.right"
            ) {
                selectedCard = .appSwitches
            }

            StatCard(
                type: .focusSessions,
                value: "\(focusSessions)",
                trend: 0.25,
                icon: "brain.head.profile"
            ) {
                selectedCard = .focusSessions
            }
        }
    }

    // MARK: - Computed Properties

    private var totalScreenTime: String {
        let total = stats.reduce(0) { $0 + $1.totalSeconds }
        return formatTime(total)
    }

    private var productiveTime: String {
        let total = stats
            .filter { (categories[$0.bundleIdentifier] ?? .neutral) == .productive }
            .reduce(0) { $0 + $1.totalSeconds }
        return formatTime(total)
    }

    private var distractedTime: String {
        let total = stats
            .filter { (categories[$0.bundleIdentifier] ?? .neutral) == .distracting }
            .reduce(0) { $0 + $1.totalSeconds }
        return formatTime(total)
    }

    private var mostUsedAppName: String {
        stats.first?.appName ?? "None"
    }

    private var appSwitches: Int {
        activities.count
    }

    private var focusSessions: Int {
        // A focus session is 25+ minutes in a productive app
        let sessions = activities.filter { activity in
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            return category == .productive && activity.durationSeconds >= 1500 // 25 min
        }
        return sessions.count
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - StatCard Component

struct StatCard: View {
    let type: StatCardType
    let value: String
    let trend: Double?
    let icon: String
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(AppTheme.animationFast) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppTheme.animationFast) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(type.color.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(type.color)
                    }

                    Spacer()

                    if let trend = trend {
                        TrendIndicator(trend: trend)
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(type.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 140)
            .background(
                ZStack {
                    // Glass morphism background
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [type.color.opacity(0.05), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                    .strokeBorder(
                        isHovering ? type.color.opacity(0.3) : Color.white.opacity(0.1),
                        lineWidth: isHovering ? 1.5 : 1
                    )
                    .animation(AppTheme.animationFast, value: isHovering)
            )
            .shadow(
                color: isHovering ? type.color.opacity(0.15) : Color.black.opacity(0.05),
                radius: isHovering ? 16 : 8,
                y: isHovering ? 8 : 4
            )
            .scaleEffect(isPressed ? 0.97 : (isHovering ? 1.02 : 1.0))
            .animation(AppTheme.animationSpring, value: isHovering)
            .animation(AppTheme.animationFast, value: isPressed)
        }
        .buttonStyle(.plain)
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

// MARK: - TrendIndicator

struct TrendIndicator: View {
    let trend: Double

    private var isPositive: Bool { trend >= 0 }
    private var color: Color { isPositive ? .green : .red }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
                .fontWeight(.semibold)
            Text("\(Int(abs(trend) * 100))%")
                .font(.caption2.bold())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .strokeBorder(color.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - StatCardType

enum StatCardType: String, Identifiable {
    case screenTime = "Total Screen Time"
    case productiveTime = "Productive Time"
    case distractedTime = "Distracted Time"
    case mostUsedApp = "Most Used App"
    case appSwitches = "App Switches"
    case focusSessions = "Focus Sessions"

    var id: String { rawValue }

    var title: String { rawValue }

    var color: Color {
        switch self {
        case .screenTime: return .blue
        case .productiveTime: return .green
        case .distractedTime: return .red
        case .mostUsedApp: return .purple
        case .appSwitches: return .orange
        case .focusSessions: return .indigo
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedCard: StatCardType? = nil

    let stats = [
        AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200),
        AppUsageStat(bundleIdentifier: "com.google.Chrome", appName: "Chrome", totalSeconds: 3600),
        AppUsageStat(bundleIdentifier: "com.apple.Safari", appName: "Safari", totalSeconds: 1800),
    ]

    let activities: [ActivityLog] = []

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.google.Chrome": CategoryType.neutral,
        "com.apple.Safari": CategoryType.neutral,
    ]

    return StatsCardsView(
        stats: stats,
        activities: activities,
        categories: categories,
        selectedCard: $selectedCard
    )
    .padding()
    .frame(width: 900)
}
