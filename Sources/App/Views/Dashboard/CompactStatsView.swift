import SwiftUI
import KafeelCore

struct CompactStatsView: View {
    let stats: [AppUsageStat]
    let activities: [ActivityLog]
    let categories: [String: CategoryType]

    var body: some View {
        HStack(spacing: 0) {
            CompactStatItem(
                icon: "desktopcomputer",
                value: totalScreenTime,
                label: "Total Time",
                color: .blue
            )

            Divider()
                .frame(height: 50)

            CompactStatItem(
                icon: "brain.head.profile",
                value: deepWorkTime,
                label: "Deep Work",
                color: .green
            )

            Divider()
                .frame(height: 50)

            CompactStatItem(
                icon: "bolt.fill",
                value: "\(flowStates)",
                label: "Flow States",
                color: .purple
            )

            Divider()
                .frame(height: 50)

            CompactStatItem(
                icon: "percent",
                value: productivePercentage,
                label: "Productive",
                color: .orange
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Computed Properties

    private var totalScreenTime: String {
        let total = stats.reduce(0) { $0 + $1.totalSeconds }
        return formatTime(total)
    }

    private var deepWorkTime: String {
        // Deep work = time in productive apps for sessions >= 25 min
        let deepWorkActivities = activities.filter { activity in
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            return category == .productive && activity.durationSeconds >= 1500 // 25 min
        }
        let total = deepWorkActivities.reduce(0) { $0 + $1.durationSeconds }
        return formatTime(total)
    }

    private var flowStates: Int {
        // Flow state = sessions >= 45 min in productive apps
        activities.filter { activity in
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            return category == .productive && activity.durationSeconds >= 2700 // 45 min
        }.count
    }

    private var productivePercentage: String {
        let totalSeconds = stats.reduce(0) { $0 + $1.totalSeconds }
        guard totalSeconds > 0 else { return "0%" }

        let productiveSeconds = stats
            .filter { (categories[$0.bundleIdentifier] ?? .neutral) == .productive }
            .reduce(0) { $0 + $1.totalSeconds }

        let percentage = Int((Double(productiveSeconds) / Double(totalSeconds)) * 100)
        return "\(percentage)%"
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

struct CompactStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let stats = [
        AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200),
        AppUsageStat(bundleIdentifier: "com.google.Chrome", appName: "Chrome", totalSeconds: 3600),
    ]

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.google.Chrome": CategoryType.neutral,
    ]

    return CompactStatsView(
        stats: stats,
        activities: [],
        categories: categories
    )
    .padding()
    .frame(width: 600)
}
