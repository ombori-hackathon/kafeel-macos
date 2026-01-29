import Foundation
import SwiftData

/// Context needed to evaluate achievement conditions
public struct AchievementContext {
    public let dailyScore: DailyScore
    public let streak: Streak
    public let userProfile: UserProfile
    public let activities: [ActivityLog]
    public let previousDayScore: DailyScore?

    public init(
        dailyScore: DailyScore,
        streak: Streak,
        userProfile: UserProfile,
        activities: [ActivityLog],
        previousDayScore: DailyScore? = nil
    ) {
        self.dailyScore = dailyScore
        self.streak = streak
        self.userProfile = userProfile
        self.activities = activities
        self.previousDayScore = previousDayScore
    }
}

/// Information about an achievement that was unlocked
public struct AchievementUnlock {
    public let type: AchievementType
    public let xpReward: Int

    public init(type: AchievementType, xpReward: Int) {
        self.type = type
        self.xpReward = xpReward
    }
}

/// Service for managing achievements and checking unlock conditions
@MainActor
public final class AchievementService {
    private let persistenceService: PersistenceService

    public init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }

    // MARK: - Public API

    /// Check all achievements against current context and unlock any that qualify
    /// - Parameter context: Context containing all data needed to evaluate achievements
    /// - Returns: Array of achievements that were newly unlocked
    public func checkAchievements(context: AchievementContext) throws -> [AchievementUnlock] {
        var unlocks: [AchievementUnlock] = []

        // Check each achievement type
        for achievementType in AchievementType.allCases {
            let achievement = try persistenceService.getOrCreateAchievement(type: achievementType)

            // Skip already unlocked non-repeatable achievements
            if achievement.isUnlocked && !isRepeatableAchievement(achievementType) {
                continue
            }

            // Check if conditions are met
            if try evaluateAchievement(type: achievementType, context: context, achievement: achievement) {
                if !achievement.isUnlocked {
                    // First time unlock
                    achievement.unlock()
                    unlocks.append(AchievementUnlock(
                        type: achievementType,
                        xpReward: achievementType.xpReward
                    ))
                } else if isRepeatableAchievement(achievementType) {
                    // Repeatable achievement - record it again
                    achievement.recordAchievement()
                }
            }
        }

        // Save if any achievements were unlocked
        if !unlocks.isEmpty {
            try persistenceService.save()
        }

        return unlocks
    }

    /// Get all achievements with their current status
    /// - Returns: Array of all Achievement objects (creates missing ones if needed)
    public func getAllAchievements() throws -> [Achievement] {
        // Ensure all achievement types exist
        for type in AchievementType.allCases {
            _ = try persistenceService.getOrCreateAchievement(type: type)
        }
        return try persistenceService.getAllAchievements()
    }

    /// Get only unlocked achievements
    /// - Returns: Array of unlocked Achievement objects, sorted by unlock date
    public func getUnlockedAchievements() throws -> [Achievement] {
        try persistenceService.getUnlockedAchievements()
    }

    // MARK: - Private Helpers

    private func isRepeatableAchievement(_ type: AchievementType) -> Bool {
        // Some achievements can be earned multiple times
        switch type {
        case .marathon, .earlyBird, .nightOwl, .meetingSurvivor, .focusMaster:
            return true
        default:
            return false
        }
    }

    private func evaluateAchievement(
        type: AchievementType,
        context: AchievementContext,
        achievement: Achievement
    ) throws -> Bool {
        switch type {
        case .firstDay:
            // First tracked day
            return context.userProfile.totalDaysTracked == 1

        case .earlyBird:
            // Productive activity before 7 AM
            return hasEarlyMorningActivity(activities: context.activities)

        case .nightOwl:
            // Productive activity after 10 PM
            return hasLateNightActivity(activities: context.activities)

        case .marathon:
            // 4+ hours continuous productive work
            return hasMarathonSession(activities: context.activities, dailyScore: context.dailyScore)

        case .streakMaster:
            // 30-day streak
            return context.streak.currentStreakDays >= 30

        case .weekWarrior:
            // 7-day streak
            return context.streak.currentStreakDays >= 7

        case .meetingSurvivor:
            // Score >= 60 with 4+ hours of meetings
            let fourHours = 4 * 3600
            return context.dailyScore.focusScore >= 60 && context.dailyScore.meetingSeconds >= fourHours

        case .comebackKid:
            // Best score after worst day
            guard let prevScore = context.previousDayScore else { return false }
            return try isComebackAchievement(
                currentScore: context.dailyScore.focusScore,
                previousScore: prevScore.focusScore
            )

        case .focusMaster:
            // Score >= 90
            return context.dailyScore.focusScore >= 90

        case .consistentPerformer:
            // Average score >= 70 for 30+ days
            return context.userProfile.totalDaysTracked >= 30 &&
                   context.userProfile.averageDailyScore >= 70
        }
    }

    // Check for productive activity before 7 AM
    private func hasEarlyMorningActivity(activities: [ActivityLog]) -> Bool {
        let calendar = Calendar.current
        for activity in activities {
            let hour = calendar.component(.hour, from: activity.startTime)
            if hour < 7 {
                // Check if this was a productive app
                if let category = persistenceService.getCategory(for: activity.appBundleIdentifier),
                   category.category == .productive {
                    return true
                }
            }
        }
        return false
    }

    // Check for productive activity after 10 PM
    private func hasLateNightActivity(activities: [ActivityLog]) -> Bool {
        let calendar = Calendar.current
        for activity in activities {
            let hour = calendar.component(.hour, from: activity.startTime)
            if hour >= 22 {
                // Check if this was a productive app
                if let category = persistenceService.getCategory(for: activity.appBundleIdentifier),
                   category.category == .productive {
                    return true
                }
            }
        }
        return false
    }

    // Check for 4+ hours of continuous productive work
    private func hasMarathonSession(activities: [ActivityLog], dailyScore: DailyScore) -> Bool {
        // Simple check: if productive seconds >= 4 hours
        let fourHours = 4 * 3600
        return dailyScore.productiveSeconds >= fourHours
    }

    // Check if current score is the best after the worst day
    private func isComebackAchievement(currentScore: Double, previousScore: Double) throws -> Bool {
        // Get the user's historical scores
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let scores = try persistenceService.fetchDailyScores(from: thirtyDaysAgo, to: Date())

        guard scores.count >= 2 else { return false }

        // Check if previous day was the worst score
        let worstScore = scores.map { $0.focusScore }.min() ?? 0
        guard previousScore <= worstScore + 5 else { return false } // Within 5 points of worst

        // Check if current score is the best or near best
        let bestScore = scores.map { $0.focusScore }.max() ?? 0
        return currentScore >= bestScore - 5 // Within 5 points of best
    }
}
