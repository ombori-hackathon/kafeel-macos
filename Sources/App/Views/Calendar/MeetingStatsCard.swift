import SwiftUI
import KafeelCore

/// Card displaying meeting statistics
struct MeetingStatsCard: View {
    let stats: MeetingStats
    let busiestDay: (day: String, duration: TimeInterval)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meeting Statistics")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MeetingStatItem(
                    title: "Total Meetings",
                    value: "\(stats.meetingCount)",
                    icon: "calendar",
                    color: .blue
                )

                MeetingStatItem(
                    title: "Meeting Time",
                    value: stats.formattedTotalTime,
                    icon: "clock",
                    color: .orange
                )

                MeetingStatItem(
                    title: "Focus Time",
                    value: stats.formattedFocusTime,
                    icon: "brain.head.profile",
                    color: .green
                )

                MeetingStatItem(
                    title: "Average Duration",
                    value: stats.formattedAverageDuration,
                    icon: "timer",
                    color: .purple
                )
            }

            if let busiest = busiestDay {
                Divider()

                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Busiest Day:")
                        .foregroundStyle(.secondary)
                    Text(busiest.day)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formatDuration(busiest.duration))
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
            }

            // Meeting load indicator
            MeetingLoadBar(percentage: stats.meetingPercentage)
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

/// Individual stat item for meeting stats
private struct MeetingStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Visual indicator of meeting load percentage
private struct MeetingLoadBar: View {
    let percentage: Double

    private var loadLevel: (color: Color, label: String) {
        switch percentage {
        case 0..<30: return (.green, "Light")
        case 30..<60: return (.yellow, "Moderate")
        case 60..<80: return (.orange, "Heavy")
        default: return (.red, "Overloaded")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Meeting Load")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(loadLevel.label)
                    .font(.caption.bold())
                    .foregroundStyle(loadLevel.color)
                Text("\(Int(percentage))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(loadLevel.color)
                        .frame(width: geometry.size.width * (percentage / 100))
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    MeetingStatsCard(
        stats: MeetingStats(
            totalMeetingTime: 4 * 3600,
            averageMeetingDuration: 1800,
            meetingCount: 8,
            meetingPercentage: 40,
            focusTime: 6 * 3600
        ),
        busiestDay: ("Wednesday", 2 * 3600)
    )
    .padding()
    .frame(width: 500)
}
