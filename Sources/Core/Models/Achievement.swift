import Foundation
import SwiftData

/// Achievement type with unlock requirements and rewards
public enum AchievementType: String, Codable, CaseIterable, Sendable {
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case marathon = "marathon"
    case streakMaster = "streak_master"
    case meetingSurvivor = "meeting_survivor"
    case comebackKid = "comeback_kid"
    case firstDay = "first_day"
    case weekWarrior = "week_warrior"
    case focusMaster = "focus_master"
    case consistentPerformer = "consistent_performer"

    public var displayName: String {
        switch self {
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .marathon: return "Marathon"
        case .streakMaster: return "Streak Master"
        case .meetingSurvivor: return "Meeting Survivor"
        case .comebackKid: return "Comeback Kid"
        case .firstDay: return "First Steps"
        case .weekWarrior: return "Week Warrior"
        case .focusMaster: return "Focus Master"
        case .consistentPerformer: return "Consistent Performer"
        }
    }

    public var description: String {
        switch self {
        case .earlyBird:
            return "Start productive work before 7 AM"
        case .nightOwl:
            return "Stay productive after 10 PM"
        case .marathon:
            return "4+ hours of uninterrupted productive work"
        case .streakMaster:
            return "Maintain a 30-day streak"
        case .meetingSurvivor:
            return "Good focus score despite 4+ hours of meetings"
        case .comebackKid:
            return "Achieve your best score after your worst day"
        case .firstDay:
            return "Complete your first tracked day"
        case .weekWarrior:
            return "7 productive days in a row"
        case .focusMaster:
            return "Achieve a score of 90 or higher"
        case .consistentPerformer:
            return "Average score above 70 for 30 days"
        }
    }

    public var icon: String {
        switch self {
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .marathon: return "figure.run"
        case .streakMaster: return "flame.fill"
        case .meetingSurvivor: return "person.3.fill"
        case .comebackKid: return "arrow.up.right"
        case .firstDay: return "star.fill"
        case .weekWarrior: return "calendar"
        case .focusMaster: return "target"
        case .consistentPerformer: return "chart.line.uptrend.xyaxis"
        }
    }

    public var xpReward: Int {
        switch self {
        case .earlyBird: return 200
        case .nightOwl: return 200
        case .marathon: return 500
        case .streakMaster: return 2000
        case .meetingSurvivor: return 300
        case .comebackKid: return 400
        case .firstDay: return 100
        case .weekWarrior: return 500
        case .focusMaster: return 300
        case .consistentPerformer: return 1000
        }
    }

    public var rarity: AchievementRarity {
        switch self {
        case .firstDay: return .common
        case .earlyBird, .nightOwl: return .uncommon
        case .marathon, .meetingSurvivor, .comebackKid, .weekWarrior, .focusMaster: return .rare
        case .consistentPerformer: return .epic
        case .streakMaster: return .legendary
        }
    }
}

public enum AchievementRarity: String, Codable, CaseIterable, Sendable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    public var colorName: String {
        switch self {
        case .common: return "gray"
        case .uncommon: return "green"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }

    public var displayName: String {
        rawValue.capitalized
    }
}

/// Tracks achievement unlock status and progress
@Model
public final class Achievement {
    @Attribute(.unique) public var typeRawValue: String
    public var isUnlocked: Bool
    public var unlockedAt: Date?
    public var progress: Double
    public var progressTarget: Double
    public var timesAchieved: Int

    public var type: AchievementType {
        AchievementType(rawValue: typeRawValue) ?? .firstDay
    }

    // MARK: - Initialization

    public init(type: AchievementType) {
        self.typeRawValue = type.rawValue
        self.isUnlocked = false
        self.unlockedAt = nil
        self.progress = 0
        self.progressTarget = Self.targetForType(type)
        self.timesAchieved = 0
    }

    // MARK: - Progress

    public var progressPercentage: Double {
        guard progressTarget > 0 else { return 0 }
        return min(progress / progressTarget, 1.0)
    }

    public var formattedProgress: String {
        let currentInt = Int(progress)
        let targetInt = Int(progressTarget)
        return "\(currentInt)/\(targetInt)"
    }

    public func updateProgress(_ newProgress: Double) {
        self.progress = min(newProgress, progressTarget)
    }

    public func incrementProgress(by amount: Double = 1) {
        self.progress = min(progress + amount, progressTarget)
    }

    public func unlock() {
        guard !isUnlocked else { return }
        self.isUnlocked = true
        self.unlockedAt = Date()
        self.progress = progressTarget
        self.timesAchieved = 1
    }

    /// For repeatable achievements (like marathon)
    public func recordAchievement() {
        if !isUnlocked {
            unlock()
        } else {
            timesAchieved += 1
        }
    }

    // MARK: - Target Configuration

    private static func targetForType(_ type: AchievementType) -> Double {
        switch type {
        case .earlyBird: return 1 // 1 early morning session
        case .nightOwl: return 1 // 1 late night session
        case .marathon: return 4 * 3600 // 4 hours in seconds
        case .streakMaster: return 30 // 30 days
        case .meetingSurvivor: return 4 * 3600 // 4 hours meetings
        case .comebackKid: return 1 // 1 occurrence
        case .firstDay: return 1 // 1 day
        case .weekWarrior: return 7 // 7 days
        case .focusMaster: return 90 // 90 score
        case .consistentPerformer: return 30 // 30 days
        }
    }
}
