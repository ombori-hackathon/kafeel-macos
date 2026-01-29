import SwiftUI
import Charts
import KafeelCore

struct HourlyActivityChart: View {
    let activities: [ActivityLog]

    private var hourlyData: [HourActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var data: [HourActivity] = []

        // Create data for hours 6am to 10pm
        for hour in 6..<22 {
            guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: today),
                  let hourEnd = calendar.date(byAdding: .hour, value: hour + 1, to: today) else {
                continue
            }

            let hourActivities = activities.filter { activity in
                let activityEnd = activity.startTime.addingTimeInterval(TimeInterval(activity.durationSeconds))
                return activity.startTime < hourEnd && activityEnd > hourStart
            }

            let totalMinutes = hourActivities.reduce(0) { $0 + $1.durationSeconds } / 60

            let label: String
            if hour == 0 {
                label = "12a"
            } else if hour < 12 {
                label = "\(hour)a"
            } else if hour == 12 {
                label = "12p"
            } else {
                label = "\(hour - 12)p"
            }

            data.append(HourActivity(hour: hour, label: label, minutes: totalMinutes))
        }

        return data
    }

    private var maxMinutes: Int {
        max(hourlyData.map { $0.minutes }.max() ?? 60, 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.cyan)
                Text("Activity by Hour")
                    .font(.headline)
                Spacer()
            }

            Chart(hourlyData) { item in
                BarMark(
                    x: .value("Hour", item.label),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(2)
            }
            .chartYScale(domain: 0...maxMinutes)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(.secondary.opacity(0.3))
                    AxisValueLabel {
                        if let minutes = value.as(Int.self) {
                            Text("\(minutes)m")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 2)) { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 120)
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
}

private struct HourActivity: Identifiable {
    let id = UUID()
    let hour: Int
    let label: String
    let minutes: Int
}

#Preview {
    HourlyActivityChart(activities: [])
        .padding()
        .frame(width: 600)
}
