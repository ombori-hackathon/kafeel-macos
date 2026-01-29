import SwiftUI
import KafeelCore

struct LevelProgressBar: View {
    let userProfile: UserProfile
    @State private var animatedProgress: Double = 0

    private var tierColor: Color {
        switch userProfile.tier {
        case .apprentice: return .green
        case .journeyman: return .blue
        case .expert: return .purple
        case .master: return .orange
        }
    }

    private var tierGradient: LinearGradient {
        switch userProfile.tier {
        case .apprentice:
            return LinearGradient(
                colors: [Color.green, Color.mint],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .journeyman:
            return LinearGradient(
                colors: [Color.blue, Color.cyan],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .expert:
            return LinearGradient(
                colors: [Color.purple, Color.pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .master:
            return LinearGradient(
                colors: [Color.orange, Color.yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with level and tier
            HStack(alignment: .center, spacing: 12) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(tierGradient)
                        .frame(width: 56, height: 56)

                    VStack(spacing: 0) {
                        Text("\(userProfile.level)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("LVL")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: userProfile.tier.icon)
                            .font(.caption)
                            .foregroundStyle(tierColor)

                        Text(userProfile.tier.rawValue)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    Text("\(formatNumber(userProfile.totalXP)) total XP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Next level indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Level \(userProfile.level + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(formatNumber(userProfile.xpForNextLevel - userProfile.totalXP)) XP")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(tierColor.opacity(0.15))
                            .frame(height: 12)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(tierGradient)
                            .frame(
                                width: geometry.size.width * animatedProgress,
                                height: 12
                            )
                            .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animatedProgress)

                        // Shimmer effect overlay
                        if animatedProgress > 0 {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * animatedProgress,
                                    height: 12
                                )
                        }
                    }
                }
                .frame(height: 12)

                // XP details
                HStack {
                    Text("\(formatNumber(userProfile.xpProgressInLevel)) / \(formatNumber(userProfile.xpRequiredForLevelUp)) XP")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(userProfile.levelProgress * 100))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(tierColor)
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
                .strokeBorder(tierColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: tierColor.opacity(0.1), radius: 10, y: 4)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3)) {
                animatedProgress = userProfile.levelProgress
            }
        }
        .onChange(of: userProfile.levelProgress) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
}

#Preview("Apprentice") {
    let profile = UserProfile()
    profile.totalXP = 500

    return LevelProgressBar(userProfile: profile)
        .frame(width: 500)
        .padding()
}

#Preview("Journeyman") {
    let profile = UserProfile()
    profile.totalXP = 15000

    return LevelProgressBar(userProfile: profile)
        .frame(width: 500)
        .padding()
}

#Preview("Expert") {
    let profile = UserProfile()
    profile.totalXP = 85000

    return LevelProgressBar(userProfile: profile)
        .frame(width: 500)
        .padding()
}

#Preview("Master") {
    let profile = UserProfile()
    profile.totalXP = 500000

    return LevelProgressBar(userProfile: profile)
        .frame(width: 500)
        .padding()
}
