import SwiftUI
import KafeelCore

struct HorizontalActivityTimeline: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]

    // Hours to display: 6am to 10pm
    private let startHour = 6
    private let endHour = 22
    private var hourRange: Range<Int> { startHour..<endHour }

    private func activityForHour(_ hour: Int) -> CategoryType? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: today),
              let hourEnd = calendar.date(byAdding: .hour, value: hour + 1, to: today) else {
            return nil
        }

        // Find activities that overlap with this hour
        let hourActivities = activities.filter { activity in
            let activityEnd = activity.startTime.addingTimeInterval(TimeInterval(activity.durationSeconds))
            return activity.startTime < hourEnd && activityEnd > hourStart
        }

        guard !hourActivities.isEmpty else { return nil }

        // Determine dominant category for this hour
        var categoryDurations: [CategoryType: Int] = [:]

        for activity in hourActivities {
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            categoryDurations[category, default: 0] += activity.durationSeconds
        }

        return categoryDurations.max(by: { $0.value < $1.value })?.key
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.purple)
                Text("Activity Timeline")
                    .font(.headline)
                Spacer()

                // Legend
                HStack(spacing: 12) {
                    LegendItem(color: .green, label: "Productive")
                    LegendItem(color: .gray, label: "Neutral")
                    LegendItem(color: .red, label: "Distracted")
                }
                .font(.caption2)
            }

            HStack(spacing: 2) {
                ForEach(Array(hourRange), id: \.self) { hour in
                    let category = activityForHour(hour)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForCategory(category))
                        .frame(height: 24)
                }
            }

            // Hour labels
            HStack {
                Text("6a")
                Spacer()
                Text("12p")
                Spacer()
                Text("6p")
                Spacer()
                Text("10p")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(20)
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

    private func colorForCategory(_ category: CategoryType?) -> Color {
        guard let category = category else {
            return Color.gray.opacity(0.2)
        }

        switch category {
        case .productive:
            return .green
        case .neutral:
            return .gray.opacity(0.5)
        case .distracting:
            return .red
        }
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HorizontalActivityTimeline(activities: [], categories: [:])
        .padding()
        .frame(width: 600)
}
