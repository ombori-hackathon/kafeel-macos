import SwiftUI
import KafeelCore

struct DailySummaryView: View {
    let dailyScore: DailyScore
    let streak: Streak
    let userProfile: UserProfile
    let newAchievements: [Achievement]
    let newRecords: [PersonalRecord]

    @Environment(\.dismiss) private var dismiss

    private var scoreColor: Color {
        switch dailyScore.focusScore {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        default: return .orange
        }
    }

    private var scoreLabel: String {
        switch dailyScore.focusScore {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Work"
        }
    }

    private var comparisonToAverage: Double? {
        guard userProfile.averageDailyScore > 0 else { return nil }
        return dailyScore.focusScore - userProfile.averageDailyScore
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Day Complete!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text(dailyScore.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Focus Score - Large display
                VStack(spacing: 16) {
                    ZStack {
                        // Animated circle
                        Circle()
                            .stroke(scoreColor.opacity(0.15), lineWidth: 16)
                            .frame(width: 180, height: 180)

                        Circle()
                            .trim(from: 0, to: dailyScore.focusScore / 100)
                            .stroke(
                                LinearGradient(
                                    colors: [scoreColor, scoreColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Text("\(Int(dailyScore.focusScore))")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(scoreColor)

                            Text(scoreLabel)
                                .font(.subheadline)
                                .foregroundStyle(scoreColor.opacity(0.8))
                        }
                    }

                    // Comparison to average
                    if let comparison = comparisonToAverage {
                        HStack(spacing: 6) {
                            Image(systemName: comparison >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                            Text(String(format: "%.1f pts %@ average", abs(comparison), comparison >= 0 ? "above" : "below"))
                                .font(.caption)
                        }
                        .foregroundStyle(comparison >= 0 ? .green : .orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill((comparison >= 0 ? Color.green : Color.orange).opacity(0.15))
                        )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                        .strokeBorder(scoreColor.opacity(0.2), lineWidth: 1)
                )

                // XP Earned
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("XP Earned Today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("+\(dailyScore.xpEarned)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                        .strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
                )

                // Streak Status
                HStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(streak.isActive ? .orange : .gray)

                    VStack(alignment: .leading, spacing: 4) {
                        if dailyScore.isProductiveDay {
                            Text("Streak Extended!")
                                .font(.subheadline)
                                .foregroundStyle(streak.isActive ? .green : .secondary)
                        } else {
                            Text("Streak Broken")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }

                        Text("\(streak.currentStreakDays) days")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                        .strokeBorder((streak.isActive ? Color.orange : Color.gray).opacity(0.2), lineWidth: 1)
                )

                // New Achievements
                if !newAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.orange)
                            Text("New Achievements")
                                .font(.headline)
                        }

                        ForEach(newAchievements, id: \.typeRawValue) { achievement in
                            HStack(spacing: 12) {
                                Image(systemName: achievement.type.icon)
                                    .font(.title3)
                                    .foregroundStyle(rarityColor(achievement.type.rarity))
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(achievement.type.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Text(achievement.type.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("+\(achievement.type.xpReward)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.yellow)
                            }
                            .padding(12)
                            .background(Color.gray.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
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
                }

                // New Records
                if !newRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("New Personal Records")
                                .font(.headline)
                        }

                        ForEach(newRecords, id: \.categoryRawValue) { record in
                            HStack(spacing: 12) {
                                Image(systemName: record.category.icon)
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.category.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    if let improvement = record.formattedImprovement {
                                        Text(improvement)
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }

                                Spacer()

                                Text(record.formattedValue)
                                    .font(.subheadline)
                                    .fontWeight(.bold)

                                if !record.category.unit.isEmpty {
                                    Text(record.category.unit)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(12)
                            .background(Color.gray.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                            .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }

                // Detailed Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Stats")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        StatItem(
                            icon: "clock.fill",
                            label: "Productive Time",
                            value: dailyScore.formattedProductiveTime,
                            color: .green
                        )

                        StatItem(
                            icon: "calendar",
                            label: "Total Time",
                            value: dailyScore.formattedTotalTime,
                            color: .blue
                        )

                        if dailyScore.meetingSeconds > 0 {
                            StatItem(
                                icon: "person.3.fill",
                                label: "Meetings",
                                value: dailyScore.formattedMeetingTime,
                                color: .purple
                            )
                        }

                        StatItem(
                            icon: "arrow.left.arrow.right",
                            label: "App Switches",
                            value: "\(dailyScore.switchCount)",
                            color: .orange
                        )
                    }

                    if let peakHours = dailyScore.peakHoursDescription {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(.green)
                            Text("Peak Hours:")
                                .foregroundStyle(.secondary)
                            Text(peakHours)
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
                        .padding(.top, 4)
                    }

                    if let distraction = dailyScore.biggestDistraction {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text("Biggest Distraction:")
                                .foregroundStyle(.secondary)
                            Text(distraction)
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
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

                // Close button
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 20)
            }
            .padding(24)
        }
        .frame(width: 500)
        .background(.ultraThinMaterial)
    }

    private func rarityColor(_ rarity: AchievementRarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }
}

#Preview("Good Day") {
    let dailyScore = DailyScore(
        date: Date(),
        focusScore: 85,
        productiveSeconds: 14400,
        distractingSeconds: 1800,
        neutralSeconds: 3600,
        meetingSeconds: 3600,
        totalSeconds: 23400,
        switchCount: 45,
        xpEarned: 850
    )
    dailyScore.setPeakHours(start: 9, end: 12)
    dailyScore.setBiggestDistraction("Slack")

    let streak = Streak()
    streak.currentStreakDays = 15
    streak.lastProductiveDate = Date()

    let profile = UserProfile()
    profile.totalXP = 5000
    profile.averageDailyScore = 72

    let achievement1 = Achievement(type: .focusMaster)
    achievement1.unlock()

    let achievement2 = Achievement(type: .marathon)
    achievement2.unlock()

    let achievements = [achievement1, achievement2]

    let records = [
        PersonalRecord(category: .bestDayScore, value: 85),
        PersonalRecord(category: .longestFocusSession, value: 7200)
    ]

    return DailySummaryView(
        dailyScore: dailyScore,
        streak: streak,
        userProfile: profile,
        newAchievements: achievements,
        newRecords: records
    )
}

#Preview("Average Day") {
    let dailyScore = DailyScore(
        date: Date(),
        focusScore: 65,
        productiveSeconds: 10800,
        distractingSeconds: 5400,
        neutralSeconds: 3600,
        totalSeconds: 19800,
        switchCount: 67,
        xpEarned: 450
    )

    let streak = Streak()
    streak.currentStreakDays = 5
    streak.lastProductiveDate = Date()

    let profile = UserProfile()
    profile.totalXP = 2500
    profile.averageDailyScore = 68

    return DailySummaryView(
        dailyScore: dailyScore,
        streak: streak,
        userProfile: profile,
        newAchievements: [],
        newRecords: []
    )
}

#Preview("Streak Broken") {
    let dailyScore = DailyScore(
        date: Date(),
        focusScore: 45,
        productiveSeconds: 7200,
        distractingSeconds: 7200,
        neutralSeconds: 3600,
        totalSeconds: 18000,
        switchCount: 95,
        xpEarned: 200
    )

    let streak = Streak()
    streak.currentStreakDays = 0
    streak.longestStreakDays = 20

    let profile = UserProfile()
    profile.totalXP = 10000
    profile.averageDailyScore = 70

    return DailySummaryView(
        dailyScore: dailyScore,
        streak: streak,
        userProfile: profile,
        newAchievements: [],
        newRecords: []
    )
}
