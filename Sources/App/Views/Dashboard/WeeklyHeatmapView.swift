import SwiftUI
import KafeelCore

struct WeeklyHeatmapView: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    @State private var selectedCell: HeatmapCell?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Activity Heatmap")
                .font(.headline)

            if activities.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    // Header with hour labels
                    HStack(spacing: 2) {
                        Text("")
                            .frame(width: 40)

                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Heatmap grid
                    ForEach(weekdays, id: \.index) { weekday in
                        HStack(spacing: 2) {
                            Text(weekday.short)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 40, alignment: .leading)

                            ForEach(0..<24, id: \.self) { hour in
                                heatmapCell(weekday: weekday.index, hour: hour)
                            }
                        }
                    }

                    // Intensity scale
                    HStack {
                        Spacer()
                        Text("Less")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ForEach(0..<5) { intensity in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(intensityColor(Double(intensity) / 4.0))
                                .frame(width: 12, height: 12)
                        }

                        Text("More")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .sheet(item: $selectedCell) { cell in
            HeatmapDetailView(
                cell: cell,
                activities: activitiesForCell(cell),
                categories: categories
            )
        }
    }

    @ViewBuilder
    private func heatmapCell(weekday: Int, hour: Int) -> some View {
        let intensity = calculateIntensity(weekday: weekday, hour: hour)
        let cell = HeatmapCell(weekday: weekday, hour: hour, intensity: intensity)

        Button(action: {
            selectedCell = cell
        }) {
            RoundedRectangle(cornerRadius: 2)
                .fill(intensityColor(intensity))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private func calculateIntensity(weekday: Int, hour: Int) -> Double {
        let activitiesInCell = activitiesForHour(weekday: weekday, hour: hour)

        guard !activitiesInCell.isEmpty else { return 0 }

        // Calculate productivity score for this hour
        var totalScore: Double = 0
        var totalDuration: Double = 0

        for activity in activitiesInCell {
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let duration = Double(activity.durationSeconds)
            totalScore += duration * category.weight
            totalDuration += duration
        }

        guard totalDuration > 0 else { return 0 }

        return totalScore / totalDuration
    }

    private func activitiesForHour(weekday: Int, hour: Int) -> [ActivityLog] {
        let calendar = Calendar.current

        return activities.filter { activity in
            let activityWeekday = calendar.component(.weekday, from: activity.startTime)
            let activityHour = calendar.component(.hour, from: activity.startTime)
            return activityWeekday == weekday && activityHour == hour
        }
    }

    private func activitiesForCell(_ cell: HeatmapCell) -> [ActivityLog] {
        activitiesForHour(weekday: cell.weekday, hour: cell.hour)
    }

    private func intensityColor(_ intensity: Double) -> Color {
        if intensity == 0 {
            return Color(nsColor: .separatorColor).opacity(0.2)
        }

        // Green gradient based on productivity
        let hue = 0.33 // Green hue
        let saturation = 0.6 + (intensity * 0.4)
        let brightness = 0.4 + (intensity * 0.6)

        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No weekly data available")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Activity patterns will appear here over the week")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private let weekdays = [
        (index: 1, short: "Sun", full: "Sunday"),
        (index: 2, short: "Mon", full: "Monday"),
        (index: 3, short: "Tue", full: "Tuesday"),
        (index: 4, short: "Wed", full: "Wednesday"),
        (index: 5, short: "Thu", full: "Thursday"),
        (index: 6, short: "Fri", full: "Friday"),
        (index: 7, short: "Sat", full: "Saturday"),
    ]
}

// MARK: - HeatmapCell

struct HeatmapCell: Identifiable {
    let id = UUID()
    let weekday: Int
    let hour: Int
    let intensity: Double

    var weekdayName: String {
        let names = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return names[weekday]
    }

    var timeRange: String {
        let endHour = (hour + 1) % 24
        return "\(hour):00 - \(endHour):00"
    }
}

// MARK: - HeatmapDetailView

struct HeatmapDetailView: View {
    let cell: HeatmapCell
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(cell.weekdayName) at \(cell.timeRange)")
                        .font(.title2.bold())
                    Text("Activity Breakdown")
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
                VStack(spacing: 16) {
                    if activities.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.badge.questionmark")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No activity during this time")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else {
                        // Productivity score
                        productivityScoreCard

                        // Activities list
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Activities")
                                .font(.headline)

                            ForEach(activities, id: \.id) { activity in
                                activityRow(activity)
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 500, height: 500)
    }

    @ViewBuilder
    private var productivityScoreCard: some View {
        let score = calculateProductivityScore()

        VStack(spacing: 8) {
            Text("Productivity Score")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("\(Int(score * 100))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor(score))

            Text(scoreLabel(score))
                .font(.subheadline)
                .foregroundStyle(scoreColor(score))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(scoreColor(score).opacity(0.1))
        )
    }

    @ViewBuilder
    private func activityRow(_ activity: ActivityLog) -> some View {
        let category = categories[activity.appBundleIdentifier] ?? .neutral

        HStack {
            Circle()
                .fill(category.color)
                .frame(width: 8, height: 8)

            Text(activity.appName)
                .font(.body)

            Spacer()

            Text(activity.formattedDuration)
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }

    private func calculateProductivityScore() -> Double {
        var totalScore: Double = 0
        var totalDuration: Double = 0

        for activity in activities {
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let duration = Double(activity.durationSeconds)
            totalScore += duration * category.weight
            totalDuration += duration
        }

        guard totalDuration > 0 else { return 0 }
        return totalScore / totalDuration
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .yellow
        case 0.2..<0.4: return .orange
        default: return .red
        }
    }

    private func scoreLabel(_ score: Double) -> String {
        switch score {
        case 0.8...1.0: return "Highly Productive"
        case 0.6..<0.8: return "Productive"
        case 0.4..<0.6: return "Neutral"
        case 0.2..<0.4: return "Somewhat Distracted"
        default: return "Distracted"
        }
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let now = Date()

    var activities: [ActivityLog] = []

    // Create sample activities across the week
    for day in 0..<7 {
        for hour in [9, 10, 11, 14, 15, 16] {
            if let date = calendar.date(byAdding: .day, value: -day, to: now),
               let activityDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) {
                let activity = ActivityLog(
                    appBundleIdentifier: "com.apple.Xcode",
                    appName: "Xcode",
                    startTime: activityDate
                )
                activity.endTime = calendar.date(byAdding: .minute, value: 45, to: activityDate)
                activity.durationSeconds = 2700
                activities.append(activity)
            }
        }
    }

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
    ]

    return VStack {
        WeeklyHeatmapView(activities: activities, categories: categories)
        WeeklyHeatmapView(activities: [], categories: [:])
    }
    .padding()
    .frame(width: 900)
}
