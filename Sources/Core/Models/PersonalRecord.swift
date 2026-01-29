import Foundation
import SwiftData

/// Category of personal record
public enum RecordCategory: String, Codable, CaseIterable, Sendable {
    case bestDayScore = "best_day_score"
    case bestWeekScore = "best_week_score"
    case longestStreak = "longest_streak"
    case mostProductiveHour = "most_productive_hour"
    case longestFocusSession = "longest_focus_session"
    case mostProductiveDay = "most_productive_day"
    case highestXPDay = "highest_xp_day"

    public var displayName: String {
        switch self {
        case .bestDayScore: return "Best Day Score"
        case .bestWeekScore: return "Best Week Score"
        case .longestStreak: return "Longest Streak"
        case .mostProductiveHour: return "Most Productive Hour"
        case .longestFocusSession: return "Longest Focus Session"
        case .mostProductiveDay: return "Most Productive Day"
        case .highestXPDay: return "Highest XP Day"
        }
    }

    public var icon: String {
        switch self {
        case .bestDayScore: return "star.fill"
        case .bestWeekScore: return "calendar.badge.checkmark"
        case .longestStreak: return "flame.fill"
        case .mostProductiveHour: return "clock.fill"
        case .longestFocusSession: return "timer"
        case .mostProductiveDay: return "trophy.fill"
        case .highestXPDay: return "sparkles"
        }
    }

    public var unit: String {
        switch self {
        case .bestDayScore, .bestWeekScore: return "pts"
        case .longestStreak: return "days"
        case .mostProductiveHour: return ""
        case .longestFocusSession: return "hrs"
        case .mostProductiveDay: return "hrs"
        case .highestXPDay: return "XP"
        }
    }
}

/// Tracks personal bests for various categories
@Model
public final class PersonalRecord {
    @Attribute(.unique) public var categoryRawValue: String
    public var value: Double
    public var achievedAt: Date
    public var details: String?
    public var previousValue: Double?
    public var improvementCount: Int

    public var category: RecordCategory {
        RecordCategory(rawValue: categoryRawValue) ?? .bestDayScore
    }

    // MARK: - Computed Properties

    public var formattedValue: String {
        let cat = category
        switch cat {
        case .bestDayScore, .bestWeekScore:
            return String(format: "%.0f", value)
        case .longestStreak:
            return "\(Int(value))"
        case .mostProductiveHour:
            let hour = Int(value)
            return String(format: "%02d:00", hour)
        case .longestFocusSession, .mostProductiveDay:
            let hours = value / 3600
            return String(format: "%.1f", hours)
        case .highestXPDay:
            return "\(Int(value))"
        }
    }

    public var improvement: Double? {
        guard let prev = previousValue, prev > 0 else { return nil }
        return ((value - prev) / prev) * 100
    }

    public var formattedImprovement: String? {
        guard let imp = improvement else { return nil }
        let sign = imp >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", imp))%"
    }

    // MARK: - Initialization

    public init(category: RecordCategory, value: Double = 0) {
        self.categoryRawValue = category.rawValue
        self.value = value
        self.achievedAt = Date()
        self.details = nil
        self.previousValue = nil
        self.improvementCount = 0
    }

    // MARK: - Update Methods

    /// Update the record if the new value is higher
    /// Returns true if a new record was set
    @discardableResult
    public func updateIfBetter(_ newValue: Double, details: String? = nil) -> Bool {
        if newValue > value {
            previousValue = value
            value = newValue
            achievedAt = Date()
            self.details = details
            improvementCount += 1
            return true
        }
        return false
    }

    /// Force update the record (for resetting or corrections)
    public func forceUpdate(_ newValue: Double, details: String? = nil) {
        previousValue = value
        value = newValue
        achievedAt = Date()
        self.details = details
    }
}
