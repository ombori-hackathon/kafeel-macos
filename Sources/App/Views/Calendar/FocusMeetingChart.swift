import SwiftUI
import Charts
import KafeelCore

/// Chart showing focus time vs meeting time
struct FocusMeetingChart: View {
    let stats: MeetingStats

    private var chartData: [TimeCategory] {
        let total = stats.totalMeetingTime + stats.focusTime

        return [
            TimeCategory(
                name: "Meeting Time",
                duration: stats.totalMeetingTime,
                percentage: total > 0 ? (stats.totalMeetingTime / total) * 100 : 0,
                color: .orange
            ),
            TimeCategory(
                name: "Focus Time",
                duration: stats.focusTime,
                percentage: total > 0 ? (stats.focusTime / total) * 100 : 0,
                color: .green
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Distribution")
                .font(.headline)

            if stats.totalMeetingTime > 0 || stats.focusTime > 0 {
                HStack(spacing: 32) {
                    // Pie chart
                    Chart(chartData, id: \.name) { category in
                        SectorMark(
                            angle: .value("Duration", category.duration),
                            innerRadius: .ratio(0.618),
                            angularInset: 2
                        )
                        .foregroundStyle(category.color)
                        .cornerRadius(4)
                    }
                    .frame(width: 200, height: 200)
                    .chartLegend(.hidden)

                    // Legend with percentages
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(chartData, id: \.name) { category in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.name)
                                        .font(.callout)
                                    Text("\(Int(category.percentage))% • \(category.formattedDuration)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No data available")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Bar chart showing daily breakdown
struct DailyFocusMeetingChart: View {
    let dailyStats: [(day: String, meetingTime: TimeInterval, focusTime: TimeInterval)]

    private var chartData: [DailyTimeData] {
        dailyStats.flatMap { stat in
            [
                DailyTimeData(day: stat.day, category: "Meetings", duration: stat.meetingTime / 3600),
                DailyTimeData(day: stat.day, category: "Focus", duration: stat.focusTime / 3600)
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Breakdown")
                .font(.headline)

            if !chartData.isEmpty {
                Chart(chartData, id: \.id) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Hours", data.duration)
                    )
                    .foregroundStyle(by: .value("Type", data.category))
                }
                .chartForegroundStyleScale([
                    "Meetings": .orange,
                    "Focus": .green
                ])
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                            }
                        }
                    }
                }
                .frame(height: 250)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No data available")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Models

private struct TimeCategory {
    let name: String
    let duration: TimeInterval
    let percentage: Double
    let color: Color

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

private struct DailyTimeData: Identifiable {
    let id = UUID()
    let day: String
    let category: String
    let duration: Double // in hours
}

#Preview("Pie Chart") {
    FocusMeetingChart(
        stats: MeetingStats(
            totalMeetingTime: 4 * 3600,
            averageMeetingDuration: 1800,
            meetingCount: 8,
            meetingPercentage: 40,
            focusTime: 6 * 3600
        )
    )
    .padding()
    .frame(width: 600)
}

#Preview("Daily Chart") {
    DailyFocusMeetingChart(
        dailyStats: [
            ("Mon", 3 * 3600, 7 * 3600),
            ("Tue", 5 * 3600, 5 * 3600),
            ("Wed", 6 * 3600, 4 * 3600),
            ("Thu", 4 * 3600, 6 * 3600),
            ("Fri", 2 * 3600, 8 * 3600)
        ]
    )
    .padding()
    .frame(width: 700)
}
