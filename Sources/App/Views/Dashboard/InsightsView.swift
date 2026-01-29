import SwiftUI
import KafeelCore

struct InsightsView: View {
    let stats: [AppUsageStat]
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    let timeFilter: TimeFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Productivity Insights")
                .font(.headline)

            if insights.isEmpty {
                emptyState
            } else {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var insights: [Insight] {
        var results: [Insight] = []

        // Most productive hour
        if let hour = mostProductiveHour {
            results.append(Insight(
                type: .positive,
                title: "Peak Productivity",
                message: "Your most productive hour is \(hour):00. Consider scheduling important work during this time.",
                icon: "chart.line.uptrend.xyaxis"
            ))
        }

        // App usage patterns
        if let mostUsed = stats.first {
            let percentage = calculatePercentage(mostUsed.totalSeconds)
            results.append(Insight(
                type: .info,
                title: "Top App",
                message: "\(mostUsed.appName) accounts for \(Int(percentage))% of your total screen time today.",
                icon: "app.badge"
            ))
        }

        // Distraction warning
        let distractedTime = calculateDistractedTime()
        let totalTime = calculateTotalTime()
        if totalTime > 0 {
            let distractedPercentage = (distractedTime / totalTime) * 100
            if distractedPercentage > 30 {
                results.append(Insight(
                    type: .warning,
                    title: "Distraction Alert",
                    message: "You're spending \(Int(distractedPercentage))% of your time in distracting apps. Consider using app blockers during focus hours.",
                    icon: "exclamationmark.triangle"
                ))
            } else if distractedPercentage < 15 {
                results.append(Insight(
                    type: .positive,
                    title: "Great Focus",
                    message: "Only \(Int(distractedPercentage))% of your time was spent on distractions. Keep up the excellent focus!",
                    icon: "checkmark.seal"
                ))
            }
        }

        // Context switching
        let switches = activities.count
        if switches > 50 {
            results.append(Insight(
                type: .warning,
                title: "High Context Switching",
                message: "You switched apps \(switches) times. Frequent switching can reduce productivity. Try batching similar tasks.",
                icon: "arrow.triangle.swap"
            ))
        } else if switches < 20 {
            results.append(Insight(
                type: .positive,
                title: "Focused Sessions",
                message: "Low app switching detected (\(switches) times). This suggests strong focus and deep work.",
                icon: "brain.head.profile"
            ))
        }

        // Focus sessions
        let focusSessions = calculateFocusSessions()
        if focusSessions > 0 {
            results.append(Insight(
                type: .positive,
                title: "Deep Work Detected",
                message: "You completed \(focusSessions) focus session\(focusSessions == 1 ? "" : "s") of 25+ minutes. Deep work drives meaningful progress!",
                icon: "crown"
            ))
        }

        // Break reminder
        if totalTime > 14400 { // 4 hours
            results.append(Insight(
                type: .tip,
                title: "Take Regular Breaks",
                message: "You've been active for \(formatHours(Int(totalTime))) today. Remember to take breaks every hour to maintain focus and health.",
                icon: "figure.walk"
            ))
        }

        return results
    }

    // MARK: - Calculations

    private var mostProductiveHour: Int? {
        var hourlyProductivity: [Int: Double] = [:]

        for activity in activities {
            let hour = Calendar.current.component(.hour, from: activity.startTime)
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let score = Double(activity.durationSeconds) * category.weight
            hourlyProductivity[hour, default: 0] += score
        }

        return hourlyProductivity.max(by: { $0.value < $1.value })?.key
    }

    private func calculateDistractedTime() -> Double {
        let distractingStats = stats.filter {
            (categories[$0.bundleIdentifier] ?? .neutral) == .distracting
        }
        return Double(distractingStats.reduce(0) { $0 + $1.totalSeconds })
    }

    private func calculateTotalTime() -> Double {
        Double(stats.reduce(0) { $0 + $1.totalSeconds })
    }

    private func calculatePercentage(_ seconds: Int) -> Double {
        let total = stats.reduce(0) { $0 + $1.totalSeconds }
        guard total > 0 else { return 0 }
        return Double(seconds) / Double(total) * 100
    }

    private func calculateFocusSessions() -> Int {
        activities.filter { activity in
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            return category == .productive && activity.durationSeconds >= 1500 // 25 min
        }.count
    }

    private func formatHours(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No insights yet")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Insights will appear as you use apps throughout the day")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Insight Model

struct Insight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let icon: String
}

enum InsightType {
    case positive
    case warning
    case info
    case tip

    var color: Color {
        switch self {
        case .positive: return .green
        case .warning: return .orange
        case .info: return .blue
        case .tip: return .purple
        }
    }

    var backgroundColor: Color {
        color.opacity(0.1)
    }
}

// MARK: - InsightCard

struct InsightCard: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundStyle(insight.type.color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(insight.type.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    let stats = [
        AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200),
        AppUsageStat(bundleIdentifier: "com.google.Chrome", appName: "Chrome", totalSeconds: 3600),
        AppUsageStat(bundleIdentifier: "com.twitter.twitter-mac", appName: "Twitter", totalSeconds: 2400),
        AppUsageStat(bundleIdentifier: "com.apple.Safari", appName: "Safari", totalSeconds: 1800),
    ]

    let calendar = Calendar.current
    let now = Date()

    var activities: [ActivityLog] = []

    // Create some sample activities
    for hour in [9, 10, 14, 15] {
        if let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) {
            let activity = ActivityLog(
                appBundleIdentifier: "com.apple.Xcode",
                appName: "Xcode",
                startTime: date
            )
            activity.endTime = calendar.date(byAdding: .minute, value: 45, to: date)
            activity.durationSeconds = 2700
            activities.append(activity)
        }
    }

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.google.Chrome": CategoryType.neutral,
        "com.twitter.twitter-mac": CategoryType.distracting,
        "com.apple.Safari": CategoryType.neutral,
    ]

    return VStack {
        InsightsView(
            stats: stats,
            activities: activities,
            categories: categories,
            timeFilter: .day
        )

        InsightsView(
            stats: [],
            activities: [],
            categories: [:],
            timeFilter: .day
        )
    }
    .padding()
    .frame(width: 700)
}
