import SwiftUI
import KafeelCore

struct AchievementGalleryView: View {
    let achievements: [Achievement]
    @State private var selectedRarity: AchievementRarity? = nil
    @State private var showUnlockedOnly = false

    private var filteredAchievements: [Achievement] {
        var filtered = achievements

        // Filter by unlocked status
        if showUnlockedOnly {
            filtered = filtered.filter { $0.isUnlocked }
        }

        // Filter by rarity
        if let rarity = selectedRarity {
            filtered = filtered.filter { $0.type.rarity == rarity }
        }

        // Sort: unlocked first, then by rarity (legendary -> common)
        return filtered.sorted { lhs, rhs in
            if lhs.isUnlocked != rhs.isUnlocked {
                return lhs.isUnlocked
            }
            if lhs.type.rarity != rhs.type.rarity {
                let rarityOrder: [AchievementRarity] = [.legendary, .epic, .rare, .uncommon, .common]
                let lhsIndex = rarityOrder.firstIndex(of: lhs.type.rarity) ?? 0
                let rhsIndex = rarityOrder.firstIndex(of: rhs.type.rarity) ?? 0
                return lhsIndex < rhsIndex
            }
            return lhs.type.displayName < rhs.type.displayName
        }
    }

    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    private var totalXPEarned: Int {
        achievements
            .filter { $0.isUnlocked }
            .reduce(0) { $0 + $1.type.xpReward * $1.timesAchieved }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with stats
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Achievements")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("\(unlockedCount) of \(achievements.count) unlocked")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Total XP earned from achievements
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundStyle(.yellow)

                            Text("\(formatNumber(totalXPEarned))")
                                .font(.title3)
                                .fontWeight(.bold)
                        }

                        Text("Total XP Earned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * (Double(unlockedCount) / Double(max(achievements.count, 1))),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
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

            // Filters
            HStack(spacing: 12) {
                // Rarity filter
                Menu {
                    Button("All Rarities") {
                        selectedRarity = nil
                    }
                    Divider()
                    ForEach(AchievementRarity.allCases, id: \.self) { rarity in
                        Button(rarity.displayName) {
                            selectedRarity = rarity
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let rarity = selectedRarity {
                            Circle()
                                .fill(rarityColor(rarity))
                                .frame(width: 8, height: 8)
                            Text(rarity.displayName)
                        } else {
                            Text("All Rarities")
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Unlocked filter toggle
                Button {
                    showUnlockedOnly.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showUnlockedOnly ? "checkmark.circle.fill" : "circle")
                        Text("Unlocked Only")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(showUnlockedOnly ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                // Result count
                Text("\(filteredAchievements.count) achievements")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            // Achievement grid
            if filteredAchievements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("No achievements found")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Try adjusting your filters")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120, maximum: 140), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredAchievements, id: \.typeRawValue) { achievement in
                            AchievementBadge(achievement: achievement)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(20)
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

#Preview {
    let achievements: [Achievement] = AchievementType.allCases.map { type in
        let achievement = Achievement(type: type)
        // Unlock some randomly
        if [true, false, false].randomElement() ?? false {
            achievement.unlock()
            if type == .marathon {
                achievement.timesAchieved = 5
            }
        } else if [true, false].randomElement() ?? false {
            // Add some progress to unlocked ones
            achievement.updateProgress(achievement.progressTarget * Double.random(in: 0.3...0.8))
        }
        return achievement
    }

    return AchievementGalleryView(achievements: achievements)
        .frame(width: 800, height: 600)
}

#Preview("All Unlocked") {
    let achievements: [Achievement] = AchievementType.allCases.map { type in
        let achievement = Achievement(type: type)
        achievement.unlock()
        return achievement
    }

    return AchievementGalleryView(achievements: achievements)
        .frame(width: 800, height: 600)
}

#Preview("Empty") {
    return AchievementGalleryView(achievements: [])
        .frame(width: 800, height: 600)
}
