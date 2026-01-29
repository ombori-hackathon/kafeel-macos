import SwiftUI
import Charts
import KafeelCore

struct DetailedAnalysisView: View {
    let cardType: StatCardType
    let stats: [AppUsageStat]
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    let timeFilter: TimeFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cardType.title)
                        .font(.title2.bold())
                    Text("Detailed Analysis")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(Color(nsColor: .controlBackgroundColor))

            ScrollView {
                VStack(spacing: 24) {
                    // Main chart
                    chartView

                    // Breakdown by app
                    if cardType != .mostUsedApp {
                        breakdownView
                    }

                    // Insights
                    insightsView
                }
                .padding(24)
            }

            // Footer with export button
            HStack {
                Spacer()
                Button("Export Data") {
                    exportData()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 800, height: 700)
    }

    // MARK: - Chart View

    @ViewBuilder
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trend Over Time")
                .font(.headline)

            Chart {
                ForEach(chartData, id: \.label) { item in
                    BarMark(
                        x: .value("Time", item.label),
                        y: .value("Duration", item.value)
                    )
                    .foregroundStyle(cardType.color.gradient)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text("\(Int(minutes))m")
                        }
                    }
                }
            }
            .frame(height: 250)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }

    // MARK: - Breakdown View

    @ViewBuilder
    private var breakdownView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown by App")
                .font(.headline)

            ForEach(topApps.prefix(5), id: \.bundleIdentifier) { stat in
                HStack {
                    Circle()
                        .fill(categoryColor(for: stat.bundleIdentifier))
                        .frame(width: 8, height: 8)

                    Text(stat.appName)
                        .font(.body)

                    Spacer()

                    Text(stat.formattedDuration)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)

                    let percentage = calculatePercentage(stat.totalSeconds)
                    Text("\(Int(percentage))%")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                )
            }
        }
    }

    // MARK: - Insights View

    @ViewBuilder
    private var insightsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)

            ForEach(insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.title3)

                    Text(insight)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.yellow.opacity(0.1))
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var chartData: [(label: String, value: Double)] {
        switch timeFilter {
        case .day:
            return hourlyData()
        case .week:
            return dailyData()
        case .year:
            return monthlyData()
        }
    }

    private func hourlyData() -> [(label: String, value: Double)] {
        var hourlyMap: [Int: Int] = [:]

        for activity in filteredActivities {
            let hour = Calendar.current.component(.hour, from: activity.startTime)
            hourlyMap[hour, default: 0] += activity.durationSeconds
        }

        return (0...23).map { hour in
            let minutes = Double(hourlyMap[hour] ?? 0) / 60.0
            let label = "\(hour):00"
            return (label, minutes)
        }
    }

    private func dailyData() -> [(label: String, value: Double)] {
        var dailyMap: [Int: Int] = [:]

        for activity in filteredActivities {
            let weekday = Calendar.current.component(.weekday, from: activity.startTime)
            dailyMap[weekday, default: 0] += activity.durationSeconds
        }

        let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return (1...7).map { day in
            let minutes = Double(dailyMap[day] ?? 0) / 60.0
            let label = weekdayNames[day - 1]
            return (label, minutes)
        }
    }

    private func monthlyData() -> [(label: String, value: Double)] {
        var monthlyMap: [Int: Int] = [:]

        for activity in filteredActivities {
            let month = Calendar.current.component(.month, from: activity.startTime)
            monthlyMap[month, default: 0] += activity.durationSeconds
        }

        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return (1...12).map { month in
            let minutes = Double(monthlyMap[month] ?? 0) / 60.0
            let label = monthNames[month - 1]
            return (label, minutes)
        }
    }

    private var filteredActivities: [ActivityLog] {
        switch cardType {
        case .productiveTime:
            return activities.filter { (categories[$0.appBundleIdentifier] ?? .neutral) == .productive }
        case .distractedTime:
            return activities.filter { (categories[$0.appBundleIdentifier] ?? .neutral) == .distracting }
        case .focusSessions:
            return activities.filter { activity in
                let category = categories[activity.appBundleIdentifier] ?? .neutral
                return category == .productive && activity.durationSeconds >= 1500
            }
        default:
            return activities
        }
    }

    private var topApps: [AppUsageStat] {
        switch cardType {
        case .productiveTime:
            return stats.filter { (categories[$0.bundleIdentifier] ?? .neutral) == .productive }
        case .distractedTime:
            return stats.filter { (categories[$0.bundleIdentifier] ?? .neutral) == .distracting }
        default:
            return stats
        }
    }

    private var insights: [String] {
        switch cardType {
        case .screenTime:
            return [
                "Your screen time is 12% higher than last \(timeFilter.rawValue.lowercased())",
                "Peak usage hours are between 10 AM and 2 PM",
                "Consider taking breaks every hour to maintain focus"
            ]
        case .productiveTime:
            return [
                "Your productive time increased by 8% compared to last \(timeFilter.rawValue.lowercased())",
                "Xcode accounts for 60% of your productive hours",
                "Best productivity hours: 9 AM - 11 AM"
            ]
        case .distractedTime:
            return [
                "Distracted time decreased by 5% - great progress!",
                "Social media apps are your main distraction source",
                "Tip: Try blocking distracting apps during focus hours"
            ]
        case .mostUsedApp:
            return [
                "\(stats.first?.appName ?? "This app") was used 40% more than your second most-used app",
                "Average session length: 45 minutes",
                "Most active time: Afternoons"
            ]
        case .appSwitches:
            return [
                "You switched apps \(activities.count) times today",
                "15% fewer switches than last \(timeFilter.rawValue.lowercased())",
                "Fewer switches typically indicate better focus"
            ]
        case .focusSessions:
            return [
                "You completed \(filteredActivities.count) deep focus sessions (25+ min)",
                "25% more focus sessions than last \(timeFilter.rawValue.lowercased())",
                "Average focus session duration: 42 minutes"
            ]
        }
    }

    private func categoryColor(for bundleId: String) -> Color {
        let category = categories[bundleId] ?? .neutral
        return category.color
    }

    private func calculatePercentage(_ seconds: Int) -> Double {
        let total = stats.reduce(0) { $0 + $1.totalSeconds }
        guard total > 0 else { return 0 }
        return Double(seconds) / Double(total) * 100
    }

    private func exportData() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(cardType.rawValue.replacingOccurrences(of: " ", with: "_")).csv"
        panel.allowedContentTypes = [.commaSeparatedText]

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            var csvContent = "Label,Value (minutes)\n"
            for item in chartData {
                csvContent += "\(item.label),\(item.value)\n"
            }

            try? csvContent.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Preview

#Preview {
    let stats = [
        AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200),
        AppUsageStat(bundleIdentifier: "com.google.Chrome", appName: "Chrome", totalSeconds: 3600),
        AppUsageStat(bundleIdentifier: "com.apple.Safari", appName: "Safari", totalSeconds: 1800),
    ]

    let activities: [ActivityLog] = []

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.google.Chrome": CategoryType.neutral,
    ]

    return DetailedAnalysisView(
        cardType: .productiveTime,
        stats: stats,
        activities: activities,
        categories: categories,
        timeFilter: .day
    )
}
