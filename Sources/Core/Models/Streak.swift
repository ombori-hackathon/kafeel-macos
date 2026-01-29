import Foundation
import SwiftData

/// Tracks the user's streak - consecutive days with score ≥60
@Model
public final class Streak {
    public var id: UUID
    public var currentStreakDays: Int
    public var longestStreakDays: Int
    public var streakShields: Int
    public var lastProductiveDate: Date?
    public var streakStartDate: Date?
    public var createdAt: Date
    public var lastUpdated: Date

    // Milestone tracking
    public var reached7Days: Bool
    public var reached30Days: Bool
    public var reached100Days: Bool

    // MARK: - Computed Properties

    public var isActive: Bool {
        guard let lastDate = lastProductiveDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)

        // Streak is active if last productive day was today or yesterday
        guard let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day else {
            return false
        }
        return daysSince <= 1
    }

    public var canUseShield: Bool {
        streakShields > 0 && currentStreakDays > 0
    }

    public var nextMilestone: Int? {
        if currentStreakDays < 7 { return 7 }
        if currentStreakDays < 30 { return 30 }
        if currentStreakDays < 100 { return 100 }
        return nil
    }

    public var progressToNextMilestone: Double {
        guard let milestone = nextMilestone else { return 1.0 }
        let previousMilestone: Int
        switch milestone {
        case 7: previousMilestone = 0
        case 30: previousMilestone = 7
        case 100: previousMilestone = 30
        default: previousMilestone = 0
        }
        let progress = currentStreakDays - previousMilestone
        let total = milestone - previousMilestone
        return Double(progress) / Double(total)
    }

    // MARK: - Initialization

    public init() {
        self.id = UUID()
        self.currentStreakDays = 0
        self.longestStreakDays = 0
        self.streakShields = 0
        self.lastProductiveDate = nil
        self.streakStartDate = nil
        self.reached7Days = false
        self.reached30Days = false
        self.reached100Days = false
        self.createdAt = Date()
        self.lastUpdated = Date()
    }

    // MARK: - Streak Management

    /// Record a productive day (score ≥ 60)
    /// Returns XP bonus earned from milestones
    public func recordProductiveDay(date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        var xpBonus = 0

        if let lastDate = lastProductiveDate {
            let lastDay = calendar.startOfDay(for: lastDate)

            if lastDay == today {
                // Already recorded today, no change
                return 0
            }

            guard let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day else {
                return 0
            }

            if daysSince == 1 {
                // Consecutive day - extend streak
                currentStreakDays += 1
            } else if daysSince == 2 && streakShields > 0 {
                // Missed one day but have a shield - use it
                streakShields -= 1
                currentStreakDays += 1 // Shield saves the streak
            } else {
                // Streak broken - start new streak
                currentStreakDays = 1
                streakStartDate = today
            }
        } else {
            // First productive day ever
            currentStreakDays = 1
            streakStartDate = today
        }

        lastProductiveDate = today
        lastUpdated = Date()

        // Update longest streak
        if currentStreakDays > longestStreakDays {
            longestStreakDays = currentStreakDays
        }

        // Check milestones and award shields/XP
        xpBonus = checkMilestones()

        return xpBonus
    }

    /// Record a non-productive day (score < 60)
    /// Returns true if streak was broken
    public func recordUnproductiveDay(date: Date = Date()) -> Bool {
        guard let lastDate = lastProductiveDate else {
            return false // No streak to break
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let lastDay = calendar.startOfDay(for: lastDate)

        guard let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day else {
            return false
        }

        // If more than 2 days since last productive day, streak is definitely broken
        if daysSince > 2 {
            currentStreakDays = 0
            streakStartDate = nil
            lastUpdated = Date()
            return true
        }

        // If exactly 2 days and no shield, streak is broken
        if daysSince == 2 && streakShields == 0 {
            currentStreakDays = 0
            streakStartDate = nil
            lastUpdated = Date()
            return true
        }

        return false
    }

    /// Manually use a shield to protect the streak
    public func useShield() -> Bool {
        guard canUseShield else { return false }
        streakShields -= 1
        lastUpdated = Date()
        return true
    }

    /// Add shields (usually from achievements or milestones)
    public func addShields(_ count: Int) {
        streakShields += count
        lastUpdated = Date()
    }

    // MARK: - Private Helpers

    private func checkMilestones() -> Int {
        var xpBonus = 0

        if currentStreakDays >= 7 && !reached7Days {
            reached7Days = true
            streakShields += 1 // Award 1 shield
            xpBonus += 500 // 7-day milestone XP
        }

        if currentStreakDays >= 30 && !reached30Days {
            reached30Days = true
            streakShields += 2 // Award 2 shields
            xpBonus += 2000 // 30-day milestone XP
        }

        if currentStreakDays >= 100 && !reached100Days {
            reached100Days = true
            streakShields += 3 // Award 3 shields
            xpBonus += 10000 // 100-day milestone XP
        }

        return xpBonus
    }
}
