import Foundation
import SwiftData

/// User profile containing level, XP, and averages for the gamification system
@Model
public final class UserProfile {
    public var id: UUID
    public var totalXP: Int
    public var currentStreak: Int
    public var longestStreak: Int
    public var totalProductiveDays: Int
    public var totalDaysTracked: Int
    public var averageDailyScore: Double
    public var createdAt: Date
    public var lastUpdated: Date

    // MARK: - Computed Properties

    public var level: Int {
        Self.levelForXP(totalXP)
    }

    public var tier: UserTier {
        UserTier.forLevel(level)
    }

    public var xpForCurrentLevel: Int {
        Self.xpRequiredForLevel(level)
    }

    public var xpForNextLevel: Int {
        Self.xpRequiredForLevel(level + 1)
    }

    public var xpProgressInLevel: Int {
        totalXP - xpForCurrentLevel
    }

    public var xpRequiredForLevelUp: Int {
        xpForNextLevel - xpForCurrentLevel
    }

    public var levelProgress: Double {
        guard xpRequiredForLevelUp > 0 else { return 1.0 }
        return Double(xpProgressInLevel) / Double(xpRequiredForLevelUp)
    }

    // MARK: - Initialization

    public init() {
        self.id = UUID()
        self.totalXP = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalProductiveDays = 0
        self.totalDaysTracked = 0
        self.averageDailyScore = 0.0
        self.createdAt = Date()
        self.lastUpdated = Date()
    }

    // MARK: - XP Operations

    public func addXP(_ amount: Int) {
        totalXP += amount
        lastUpdated = Date()
    }

    public func updateAverageScore(newScore: Double) {
        if totalDaysTracked == 0 {
            averageDailyScore = newScore
        } else {
            // Running average
            averageDailyScore = ((averageDailyScore * Double(totalDaysTracked)) + newScore) / Double(totalDaysTracked + 1)
        }
        totalDaysTracked += 1
        lastUpdated = Date()
    }

    // MARK: - Level Calculation

    /// XP required to reach a specific level
    public static func xpRequiredForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        // Exponential curve: each level requires progressively more XP
        // Level 2: 100, Level 10: ~10K, Level 25: ~75K, Level 50: ~350K
        return Int(pow(Double(level - 1), 2.5) * 50)
    }

    /// Calculate level from total XP
    public static func levelForXP(_ xp: Int) -> Int {
        var level = 1
        while xpRequiredForLevel(level + 1) <= xp {
            level += 1
        }
        return level
    }
}

// MARK: - User Tier

public enum UserTier: String, Codable, CaseIterable, Sendable {
    case apprentice = "Apprentice"
    case journeyman = "Journeyman"
    case expert = "Expert"
    case master = "Master"

    public static func forLevel(_ level: Int) -> UserTier {
        switch level {
        case 1...10: return .apprentice
        case 11...25: return .journeyman
        case 26...50: return .expert
        default: return .master
        }
    }

    public var icon: String {
        switch self {
        case .apprentice: return "leaf.fill"
        case .journeyman: return "hammer.fill"
        case .expert: return "star.fill"
        case .master: return "crown.fill"
        }
    }

    public var colorName: String {
        switch self {
        case .apprentice: return "green"
        case .journeyman: return "blue"
        case .expert: return "purple"
        case .master: return "orange"
        }
    }
}
