import SwiftUI
import Charts
import KafeelCore

struct WeeklyHoursChart: View {
    let activities: [ActivityLog]

    private var weeklyData: [DayHours] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get the start of the current week (Monday)
        var weekStart = today
        if let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start {
            weekStart = start
        }

        // Create data for each day of the week
        var data: [DayHours] = []
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        for dayOffset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: dayDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            // Sum up hours for this day
            let dayActivities = activities.filter { activity in
                activity.startTime >= dayStart && activity.startTime < dayEnd
            }

            let totalSeconds = dayActivities.reduce(0) { $0 + $1.durationSeconds }
            let hours = Double(totalSeconds) / 3600.0

            data.append(DayHours(
                day: dayNames[dayOffset],
                hours: hours,
                isToday: calendar.isDateInToday(dayDate)
            ))
        }

        return data
    }

    private var maxHours: Double {
        max(weeklyData.map { $0.hours }.max() ?? 8, 8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text("Weekly Hours")
                    .font(.headline)
                Spacer()
            }

            Chart(weeklyData) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Hours", item.hours)
                )
                .foregroundStyle(item.isToday ? Color.blue : Color.blue.opacity(0.6))
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...maxHours)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(.secondary.opacity(0.3))
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
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

private struct DayHours: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
    let isToday: Bool
}

#Preview {
    WeeklyHoursChart(activities: [])
        .padding()
        .frame(width: 400)
}
