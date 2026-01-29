import SwiftUI
import KafeelCore

struct AchievementBadge: View {
    let achievement: Achievement
    @State private var isHovered = false

    private var rarityColor: Color {
        switch achievement.type.rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }

    private var rarityGradient: LinearGradient {
        switch achievement.type.rarity {
        case .common:
            return LinearGradient(
                colors: [Color.gray, Color.gray.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .uncommon:
            return LinearGradient(
                colors: [Color.green, Color.mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .rare:
            return LinearGradient(
                colors: [Color.blue, Color.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .epic:
            return LinearGradient(
                colors: [Color.purple, Color.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .legendary:
            return LinearGradient(
                colors: [Color.orange, Color.yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Badge icon container
            ZStack {
                // Outer glow for unlocked achievements
                if achievement.isUnlocked {
                    Circle()
                        .fill(rarityGradient)
                        .blur(radius: isHovered ? 12 : 8)
                        .opacity(isHovered ? 0.6 : 0.4)
                        .scaleEffect(isHovered ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isHovered)
                }

                // Main badge circle
                Circle()
                    .strokeBorder(
                        achievement.isUnlocked ? rarityGradient : LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
                    .frame(width: 80, height: 80)

                // Icon
                Image(systemName: achievement.type.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(
                        achievement.isUnlocked ? rarityGradient : LinearGradient(
                            colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .saturation(achievement.isUnlocked ? 1.0 : 0.0)

                // Progress ring for incomplete achievements
                if !achievement.isUnlocked && achievement.progressPercentage > 0 {
                    Circle()
                        .trim(from: 0, to: achievement.progressPercentage)
                        .stroke(
                            rarityColor.opacity(0.5),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 86, height: 86)
                        .rotationEffect(.degrees(-90))
                }

                // Times achieved indicator
                if achievement.timesAchieved > 1 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(rarityColor)
                                    .frame(width: 24, height: 24)

                                Text("\(achievement.timesAchieved)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: 8, y: 8)
                        }
                    }
                    .frame(width: 80, height: 80)
                }
            }
            .frame(width: 80, height: 80)

            // Achievement name
            Text(achievement.type.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)

            // Rarity badge
            Text(achievement.type.rarity.displayName.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(achievement.isUnlocked ? rarityColor : .gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(rarityColor.opacity(achievement.isUnlocked ? 0.15 : 0.05))
                )

            // XP reward
            if achievement.isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 8))
                    Text("+\(achievement.type.xpReward) XP")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.secondary)
            } else if achievement.progressPercentage > 0 {
                // Progress text
                Text(achievement.formattedProgress)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 120)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(isHovered ? 1.0 : 0.8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .strokeBorder(
                    achievement.isUnlocked ? rarityColor.opacity(0.3) : Color.gray.opacity(0.1),
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .shadow(
            color: achievement.isUnlocked ? rarityColor.opacity(0.2) : .black.opacity(0.05),
            radius: isHovered ? 12 : 8,
            y: 4
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .help(achievement.type.description)
    }
}

#Preview("Unlocked Common") {
    let achievement = Achievement(type: .firstDay)
    achievement.unlock()

    return AchievementBadge(achievement: achievement)
        .padding()
}

#Preview("Unlocked Legendary") {
    let achievement = Achievement(type: .streakMaster)
    achievement.unlock()
    achievement.timesAchieved = 3

    return AchievementBadge(achievement: achievement)
        .padding()
}

#Preview("In Progress") {
    let achievement = Achievement(type: .marathon)
    achievement.updateProgress(7200) // 50% of 4 hours

    return AchievementBadge(achievement: achievement)
        .padding()
}

#Preview("Locked") {
    let achievement = Achievement(type: .focusMaster)

    return AchievementBadge(achievement: achievement)
        .padding()
}

#Preview("Grid") {
    let achievement1 = Achievement(type: .firstDay)
    achievement1.unlock()

    let achievement2 = Achievement(type: .earlyBird)
    achievement2.unlock()
    achievement2.timesAchieved = 5

    let achievement3 = Achievement(type: .marathon)
    achievement3.updateProgress(2000)

    let achievement4 = Achievement(type: .streakMaster)

    let achievement5 = Achievement(type: .focusMaster)
    achievement5.unlock()

    let achievement6 = Achievement(type: .nightOwl)

    let achievements = [achievement1, achievement2, achievement3, achievement4, achievement5, achievement6]

    return ScrollView {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 120), spacing: 16)
        ], spacing: 16) {
            ForEach(achievements, id: \.typeRawValue) { achievement in
                AchievementBadge(achievement: achievement)
            }
        }
        .padding()
    }
    .frame(width: 600, height: 400)
}
