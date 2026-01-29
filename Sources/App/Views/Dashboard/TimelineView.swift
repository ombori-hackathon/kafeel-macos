import SwiftUI
import KafeelCore

struct TimelineView: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    @State private var hoveredBlock: TimelineBlock?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Timeline")
                .font(.headline)

            if activities.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    // Hour labels
                    HStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Timeline bars
                    HStack(spacing: 2) {
                        ForEach(0..<24, id: \.self) { hour in
                            hourColumn(hour: hour)
                        }
                    }
                    .frame(height: 80)

                    // Legend
                    HStack(spacing: 16) {
                        legendItem(color: .green, label: "Productive")
                        legendItem(color: .gray, label: "Neutral")
                        legendItem(color: .red, label: "Distracting")
                        legendItem(color: Color(nsColor: .separatorColor), label: "No tracking")
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .popover(item: $hoveredBlock) { block in
            TimelineTooltip(block: block)
        }
    }

    @ViewBuilder
    private func hourColumn(hour: Int) -> some View {
        let blocks = timelineBlocks(for: hour)

        VStack(spacing: 1) {
            ForEach(blocks) { block in
                RoundedRectangle(cornerRadius: 2)
                    .fill(block.color)
                    .frame(height: blockHeight(for: block))
                    .onHover { hovering in
                        if hovering {
                            hoveredBlock = block
                        } else if hoveredBlock?.id == block.id {
                            hoveredBlock = nil
                        }
                    }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(nsColor: .separatorColor).opacity(0.2))
        )
    }

    private func timelineBlocks(for hour: Int) -> [TimelineBlock] {
        let calendar = Calendar.current
        let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart)!

        let activitiesInHour = activities.filter { activity in
            activity.startTime < hourEnd && (activity.endTime ?? Date()) > hourStart
        }

        return activitiesInHour.map { activity in
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let start = max(activity.startTime, hourStart)
            let end = min(activity.endTime ?? Date(), hourEnd)
            let duration = end.timeIntervalSince(start)

            return TimelineBlock(
                id: activity.id,
                appName: activity.appName,
                duration: duration,
                category: category
            )
        }
    }

    private func blockHeight(for block: TimelineBlock) -> CGFloat {
        let totalHeight: CGFloat = 80
        let hourDuration: TimeInterval = 3600
        return (block.duration / hourDuration) * totalHeight
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "timeline.selection")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No activity tracked today")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Your hourly activity will appear here")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 8)
            Text(label)
        }
    }
}

// MARK: - TimelineBlock

struct TimelineBlock: Identifiable {
    let id: UUID
    let appName: String
    let duration: TimeInterval
    let category: CategoryType

    var color: Color {
        category.color
    }

    var formattedDuration: String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - TimelineTooltip

struct TimelineTooltip: View {
    let block: TimelineBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(block.color)
                    .frame(width: 8, height: 8)
                Text(block.appName)
                    .font(.headline)
            }

            Divider()

            HStack {
                Text("Duration:")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(block.formattedDuration)
                    .font(.body.monospacedDigit())
            }

            HStack {
                Text("Category:")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(block.category.displayName)
                    .foregroundStyle(block.color)
            }
        }
        .font(.caption)
        .padding(12)
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(radius: 8)
        )
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let now = Date()

    let activities = [
        ActivityLog(
            appBundleIdentifier: "com.apple.Xcode",
            appName: "Xcode",
            startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        ),
        ActivityLog(
            appBundleIdentifier: "com.google.Chrome",
            appName: "Chrome",
            startTime: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now)!
        ),
        ActivityLog(
            appBundleIdentifier: "com.apple.Safari",
            appName: "Safari",
            startTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now)!
        ),
    ]

    // Set end times and durations
    activities[0].endTime = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: now)!
    activities[0].durationSeconds = 5400 // 90 min

    activities[1].endTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!
    activities[1].durationSeconds = 3600 // 60 min

    activities[2].endTime = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: now)!
    activities[2].durationSeconds = 5400 // 90 min

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.google.Chrome": CategoryType.neutral,
        "com.apple.Safari": CategoryType.distracting,
    ]

    return VStack {
        TimelineView(activities: activities, categories: categories)
        TimelineView(activities: [], categories: [:])
    }
    .padding()
    .frame(width: 900)
}
