import SwiftUI
import KafeelCore

struct PersonalBestCard: View {
    let todayScore: Double
    let records: [PersonalRecord]
    let streak: Streak

    private var bestDayRecord: PersonalRecord? {
        records.first { $0.category == .bestDayScore }
    }

    private var scoreComparison: Double? {
        guard let bestDay = bestDayRecord, bestDay.value > 0 else { return nil }
        return (todayScore / bestDay.value) * 100
    }

    private var isCloseToRecord: Bool {
        guard let comparison = scoreComparison else { return false }
        return comparison >= 85 && comparison < 100
    }

    private var isBeatRecord: Bool {
        guard let comparison = scoreComparison else { return false }
        return comparison >= 100
    }

    private var streakComparison: Double? {
        guard streak.longestStreakDays > 0 else { return nil }
        return (Double(streak.currentStreakDays) / Double(streak.longestStreakDays)) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                Text("Personal Bests")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()
            }

            // Today's Score vs Best
            if let bestDay = bestDayRecord {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Best Day Score")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if let comparison = scoreComparison {
                            if isBeatRecord {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                    Text("New Record!")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.green)
                                }
                            } else if isCloseToRecord {
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                    Text("\(Int(comparison))%")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        // Today's score
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(String(format: "%.0f", todayScore))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 6)

                                if let comparison = scoreComparison {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(
                                            isBeatRecord ? Color.green :
                                            isCloseToRecord ? Color.orange :
                                            Color.blue
                                        )
                                        .frame(
                                            width: min(geometry.size.width * (comparison / 100), geometry.size.width),
                                            height: 6
                                        )
                                }
                            }
                        }
                        .frame(height: 6)

                        // Best score
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Best")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(bestDay.formattedValue)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Divider()

            // Streak Comparison
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Longest Streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if streak.currentStreakDays == streak.longestStreakDays && streak.isActive {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            Text("Tied!")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.yellow)
                        }
                    }
                }

                HStack(spacing: 12) {
                    // Current streak
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        HStack(spacing: 4) {
                            Text("\(streak.currentStreakDays)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(streak.isActive ? .primary : .secondary)
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(streak.isActive ? .green : .gray)
                        }
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)

                            if let comparison = streakComparison {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(
                                        streak.isActive ?
                                            LinearGradient(
                                                colors: [Color.orange, Color.red],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ) :
                                            LinearGradient(
                                                colors: [Color.gray, Color.gray.opacity(0.5)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                    )
                                    .frame(
                                        width: min(geometry.size.width * (comparison / 100), geometry.size.width),
                                        height: 6
                                    )
                            }
                        }
                    }
                    .frame(height: 6)

                    // Longest streak
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Best")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        HStack(spacing: 4) {
                            Text("\(streak.longestStreakDays)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Image(systemName: "trophy.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            // Additional records
            if records.count > 1 {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Other Records")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    ForEach(records.filter { $0.category != .bestDayScore }.prefix(3), id: \.categoryRawValue) { record in
                        HStack {
                            Image(systemName: record.category.icon)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: 16)

                            Text(record.category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(record.formattedValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)

                            if !record.category.unit.isEmpty {
                                Text(record.category.unit)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
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
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .orange.opacity(0.1), radius: 10, y: 4)
    }
}

#Preview("Beating Record") {
    let records = [
        PersonalRecord(category: .bestDayScore, value: 85),
        PersonalRecord(category: .longestFocusSession, value: 10800),
        PersonalRecord(category: .highestXPDay, value: 1500)
    ]

    let streak = Streak()
    streak.currentStreakDays = 18
    streak.longestStreakDays = 25
    streak.lastProductiveDate = Date()

    return PersonalBestCard(
        todayScore: 92,
        records: records,
        streak: streak
    )
    .frame(width: 400)
    .padding()
}

#Preview("Close to Record") {
    let records = [
        PersonalRecord(category: .bestDayScore, value: 90),
        PersonalRecord(category: .longestStreak, value: 30)
    ]

    let streak = Streak()
    streak.currentStreakDays = 15
    streak.longestStreakDays = 30
    streak.lastProductiveDate = Date()

    return PersonalBestCard(
        todayScore: 82,
        records: records,
        streak: streak
    )
    .frame(width: 400)
    .padding()
}

#Preview("Tied Record") {
    let records = [
        PersonalRecord(category: .bestDayScore, value: 88)
    ]

    let streak = Streak()
    streak.currentStreakDays = 25
    streak.longestStreakDays = 25
    streak.lastProductiveDate = Date()

    return PersonalBestCard(
        todayScore: 75,
        records: records,
        streak: streak
    )
    .frame(width: 400)
    .padding()
}
