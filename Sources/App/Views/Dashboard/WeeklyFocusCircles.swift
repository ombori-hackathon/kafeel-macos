import SwiftUI
import KafeelCore

struct WeeklyFocusCircles: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]

    private var weeklyScores: [DayScore] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get the start of the current week (Monday)
        var weekStart = today
        if let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start {
            weekStart = start
        }

        let dayNames = ["M", "T", "W", "T", "F", "S", "S"]
        var scores: [DayScore] = []

        for dayOffset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: dayDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            let dayActivities = activities.filter { activity in
                activity.startTime >= dayStart && activity.startTime < dayEnd
            }

            let score = calculateFocusScore(for: dayActivities)
            let isToday = calendar.isDateInToday(dayDate)
            let isFuture = dayDate > today

            scores.append(DayScore(
                day: dayNames[dayOffset],
                score: score,
                isToday: isToday,
                isFuture: isFuture
            ))
        }

        return scores
    }

    private func calculateFocusScore(for activities: [ActivityLog]) -> Double {
        guard !activities.isEmpty else { return 0 }

        var totalWeightedTime: Double = 0
        var totalTime: Double = 0

        for activity in activities {
            let duration = Double(activity.durationSeconds)
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let weight = category.weight

            totalWeightedTime += duration * weight
            totalTime += duration
        }

        return totalTime > 0 ? (totalWeightedTime / totalTime) * 100 : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundStyle(.indigo)
                Text("Weekly Focus")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(weeklyScores) { dayScore in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .stroke(dayScore.isFuture ? Color.gray.opacity(0.2) : scoreColor(dayScore.score).opacity(0.2), lineWidth: 4)
                                .frame(width: 44, height: 44)

                            if !dayScore.isFuture {
                                Circle()
                                    .trim(from: 0, to: dayScore.score / 100)
                                    .stroke(scoreColor(dayScore.score), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 44, height: 44)
                                    .rotationEffect(.degrees(-90))
                            }

                            Text("\(Int(dayScore.score))")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(dayScore.isFuture ? .secondary : .primary)
                        }

                        Text(dayScore.day)
                            .font(.caption2)
                            .foregroundStyle(dayScore.isToday ? .primary : .secondary)
                            .fontWeight(dayScore.isToday ? .bold : .regular)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
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

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }
}

private struct DayScore: Identifiable {
    let id = UUID()
    let day: String
    let score: Double
    let isToday: Bool
    let isFuture: Bool
}

#Preview {
    WeeklyFocusCircles(activities: [], categories: [:])
        .padding()
        .frame(width: 400)
}
