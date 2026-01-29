import SwiftUI
import KafeelCore

struct StreakCard: View {
    let streak: Streak
    @State private var animatedProgress: Double = 0

    private var streakColor: Color {
        streak.isActive ? .green : .gray
    }

    private var progressColor: LinearGradient {
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
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(streakColor)

                Text("Streak")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                // Shields
                if streak.streakShields > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("\(streak.streakShields)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            // Current Streak Display
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(streak.currentStreakDays)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(streakColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("days")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    if streak.currentStreakDays > 0 {
                        Text(streak.isActive ? "active" : "broken")
                            .font(.caption)
                            .foregroundStyle(streak.isActive ? .green : .red)
                    }
                }

                Spacer()
            }

            // Progress to next milestone
            if let milestone = streak.nextMilestone {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Next milestone: \(milestone) days")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(streak.currentStreakDays)/\(milestone)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)

                            // Progress
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(progressColor)
                                .frame(
                                    width: geometry.size.width * animatedProgress,
                                    height: 8
                                )
                                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedProgress)
                        }
                    }
                    .frame(height: 8)
                }
            } else {
                // Max milestone reached
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.orange)
                    Text("All milestones reached!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Longest Streak
            if streak.longestStreakDays > 0 {
                Divider()

                HStack {
                    Text("Best streak:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(streak.longestStreakDays) days")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if streak.currentStreakDays == streak.longestStreakDays && streak.isActive {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
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
                .strokeBorder(streakColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: streakColor.opacity(0.1), radius: 10, y: 4)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedProgress = streak.progressToNextMilestone
            }
        }
        .onChange(of: streak.progressToNextMilestone) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview("Active Streak") {
    let streak = Streak()
    streak.currentStreakDays = 15
    streak.longestStreakDays = 20
    streak.streakShields = 2
    streak.lastProductiveDate = Date()
    streak.reached7Days = true

    return StreakCard(streak: streak)
        .frame(width: 400)
        .padding()
}

#Preview("Broken Streak") {
    let streak = Streak()
    streak.currentStreakDays = 8
    streak.longestStreakDays = 25
    streak.streakShields = 0
    streak.lastProductiveDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())

    return StreakCard(streak: streak)
        .frame(width: 400)
        .padding()
}

#Preview("Max Milestone") {
    let streak = Streak()
    streak.currentStreakDays = 150
    streak.longestStreakDays = 150
    streak.streakShields = 6
    streak.lastProductiveDate = Date()
    streak.reached7Days = true
    streak.reached30Days = true
    streak.reached100Days = true

    return StreakCard(streak: streak)
        .frame(width: 400)
        .padding()
}
