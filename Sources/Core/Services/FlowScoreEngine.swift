import Foundation
import SwiftData
import Observation

// MARK: - Result Types

public struct FlowDayStats {
    public let focusScore: Double
    public let productiveSeconds: Int
    public let distractingSeconds: Int
    public let neutralSeconds: Int
    public let meetingSeconds: Int
    public let totalSeconds: Int
    public let switchCount: Int
    public let xpEarned: Int
    public let currentStreak: Int
    public let level: Int
    public let tier: UserTier

    public init(
        focusScore: Double,
        productiveSeconds: Int,
        distractingSeconds: Int,
        neutralSeconds: Int,
        meetingSeconds: Int,
        totalSeconds: Int,
        switchCount: Int,
        xpEarned: Int,
        currentStreak: Int,
        level: Int,
        tier: UserTier
    ) {
        self.focusScore = focusScore
        self.productiveSeconds = productiveSeconds
        self.distractingSeconds = distractingSeconds
        self.neutralSeconds = neutralSeconds
        self.meetingSeconds = meetingSeconds
        self.totalSeconds = totalSeconds
        self.switchCount = switchCount
        self.xpEarned = xpEarned
        self.currentStreak = currentStreak
        self.level = level
        self.tier = tier
    }
}

public struct DayFinalizationResult {
    public let dailyScore: DailyScore
    public let streakResult: StreakResult
    public let recordUpdates: [RecordUpdate]
    public let achievementUnlocks: [AchievementUnlock]
    public let totalXPEarned: Int

    public init(
        dailyScore: DailyScore,
        streakResult: StreakResult,
        recordUpdates: [RecordUpdate],
        achievementUnlocks: [AchievementUnlock],
        totalXPEarned: Int
    ) {
        self.dailyScore = dailyScore
        self.streakResult = streakResult
        self.recordUpdates = recordUpdates
        self.achievementUnlocks = achievementUnlocks
        self.totalXPEarned = totalXPEarned
    }
}

// MARK: - FlowScoreEngine

@MainActor
@Observable
public final class FlowScoreEngine {
    public private(set) var currentScore: Double = 0
    public private(set) var currentXP: Int = 0
    public private(set) var todayXPEarned: Int = 0

    private let persistenceService: PersistenceService
    private let meetingDetector: MeetingDetector
    private let streakService: StreakService
    private let achievementService: AchievementService
    private let recordService: PersonalRecordService

    public init(
        persistenceService: PersistenceService = .shared,
        meetingDetector: MeetingDetector,
        streakService: StreakService? = nil,
        achievementService: AchievementService? = nil,
        recordService: PersonalRecordService? = nil
    ) {
        self.persistenceService = persistenceService
        self.meetingDetector = meetingDetector
        self.streakService = streakService ?? StreakService(persistenceService: persistenceService)
        self.achievementService = achievementService ?? AchievementService(persistenceService: persistenceService)
        self.recordService = recordService ?? PersonalRecordService(persistenceService: persistenceService)

        // Load initial state
        do {
            let profile = try persistenceService.getOrCreateUserProfile()
            self.currentXP = profile.totalXP

            let dailyScore = try persistenceService.getOrCreateDailyScore(for: Date())
            self.todayXPEarned = dailyScore.xpEarned
        } catch {
            print("FlowScoreEngine: Error loading initial state: \(error)")
        }
    }

    // MARK: - Public Methods

    /// Process activity and update scores
    /// Call this after saving each ActivityLog
    public func processActivity(activity: ActivityLog, categories: [String: CategoryType]) throws {
        let stats = try calculateTodayStats()
        currentScore = stats.focusScore

        // Update today's daily score record
        let dailyScore = try persistenceService.getOrCreateDailyScore(for: Date())
        dailyScore.updateFromStats(
            focusScore: stats.focusScore,
            productiveSeconds: stats.productiveSeconds,
            distractingSeconds: stats.distractingSeconds,
            neutralSeconds: stats.neutralSeconds,
            meetingSeconds: stats.meetingSeconds,
            switchCount: stats.switchCount
        )

        try persistenceService.save()
    }

    /// Calculate and return today's comprehensive stats
    public func calculateTodayStats() throws -> FlowDayStats {
        let today = Date()

        // Fetch today's activities
        let activities = try persistenceService.fetchActivities(for: today)

        // Get categories
        let categories = try getCategoryMappings()

        // Calculate focus stats
        let focusStats = FocusScoreCalculator.calculateStats(
            activities: activities,
            categories: categories,
            defaultCategory: .neutral
        )

        // Get meeting time
        let meetingSeconds = try meetingDetector.getTodayMeetingSeconds()

        // Get daily score
        let dailyScore = try persistenceService.getOrCreateDailyScore(for: today)

        // Get streak
        let streak = try persistenceService.getOrCreateStreak()

        // Get profile
        let profile = try persistenceService.getOrCreateUserProfile()

        return FlowDayStats(
            focusScore: focusStats.focusScore,
            productiveSeconds: focusStats.productiveSeconds,
            distractingSeconds: focusStats.distractingSeconds,
            neutralSeconds: focusStats.neutralSeconds,
            meetingSeconds: meetingSeconds,
            totalSeconds: focusStats.totalSeconds,
            switchCount: focusStats.switchCount,
            xpEarned: dailyScore.xpEarned,
            currentStreak: streak.currentStreakDays,
            level: profile.level,
            tier: profile.tier
        )
    }

    /// Finalize the day - call at end of day or when app closes
    public func finalizeDay() throws -> DayFinalizationResult {
        let stats = try calculateTodayStats()
        let today = Date()

        // Get or create daily score
        let dailyScore = try persistenceService.getOrCreateDailyScore(for: today)

        // Update streak using StreakService
        let streakResult = try streakService.processDay(date: today, focusScore: stats.focusScore)

        // Get updated streak for XP calculation
        let streak = try streakService.getCurrentStreak()

        // Calculate XP (base + streak bonus + meeting bonus + milestone bonus)
        let xp = calculateDayXP(stats: stats, streak: streak, milestoneXP: streakResult.xpBonus)
        dailyScore.setXPEarned(xp.total)
        todayXPEarned = xp.total

        // Update user profile
        let profile = try persistenceService.getOrCreateUserProfile()
        profile.addXP(xp.total)
        profile.updateAverageScore(newScore: stats.focusScore)
        if stats.focusScore >= 60 {
            profile.totalProductiveDays += 1
        }
        currentXP = profile.totalXP

        // Check for achievements using AchievementService
        let activities = try persistenceService.fetchActivities(for: today)
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let previousDayScore = try persistenceService.getDailyScore(for: yesterday)

        let achievementContext = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: activities,
            previousDayScore: previousDayScore
        )
        let achievementUnlocks = try achievementService.checkAchievements(context: achievementContext)

        // Add XP from achievement unlocks
        let achievementXP = achievementUnlocks.reduce(0) { $0 + $1.xpReward }
        if achievementXP > 0 {
            profile.addXP(achievementXP)
            dailyScore.setXPEarned(dailyScore.xpEarned + achievementXP)
            currentXP = profile.totalXP
            todayXPEarned = dailyScore.xpEarned
        }

        // Check for personal records using PersonalRecordService
        let recordUpdates = try recordService.checkAndUpdateRecords(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile
        )

        // Analyze peak hours and biggest distraction
        try analyzeDayPatterns(stats: stats, dailyScore: dailyScore)

        try persistenceService.save()

        return DayFinalizationResult(
            dailyScore: dailyScore,
            streakResult: streakResult,
            recordUpdates: recordUpdates,
            achievementUnlocks: achievementUnlocks,
            totalXPEarned: dailyScore.xpEarned
        )
    }

    /// Get current user profile
    public func getUserProfile() throws -> UserProfile {
        return try persistenceService.getOrCreateUserProfile()
    }

    /// Get current streak
    public func getStreak() throws -> Streak {
        return try streakService.getCurrentStreak()
    }

    // MARK: - Private Methods

    private func getCategoryMappings() throws -> [String: CategoryType] {
        // This would fetch all AppCategory records from the database
        // For now, we'll use a simple implementation that would be enhanced later
        // In a full implementation, you'd query all AppCategory records and build the dictionary
        return [:]
    }

    private func calculateDayXP(
        stats: FlowDayStats,
        streak: Streak,
        milestoneXP: Int
    ) -> (base: Int, streak: Int, meeting: Int, milestone: Int, total: Int) {
        // Base XP = focusScore * 10
        let baseXP = Int(stats.focusScore * 10)

        // Streak bonus = currentStreak * 50
        let streakBonus = streak.currentStreakDays * 50

        // Meeting bonus = meetingSeconds / 3600 * 100 (per hour of meetings)
        let meetingBonus = (stats.meetingSeconds / 3600) * 100

        // Milestone XP from streak achievements
        let milestone = milestoneXP

        let total = baseXP + streakBonus + meetingBonus + milestone

        return (base: baseXP, streak: streakBonus, meeting: meetingBonus, milestone: milestone, total: total)
    }

    private func analyzeDayPatterns(stats: FlowDayStats, dailyScore: DailyScore) throws {
        // Get today's activities
        let activities = try persistenceService.fetchActivities(for: Date())

        // Find peak hours (hour with most productive time)
        var hourlyProductive: [Int: Int] = [:]
        let categories = try getCategoryMappings()

        for activity in activities {
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            guard category == .productive else { continue }

            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: activity.startTime)
            hourlyProductive[hour, default: 0] += activity.durationSeconds
        }

        if let peakHour = hourlyProductive.max(by: { $0.value < $1.value }) {
            dailyScore.setPeakHours(start: peakHour.key, end: peakHour.key + 1)
        }

        // Find biggest distraction (most time on distracting app)
        var distractionTime: [String: Int] = [:]
        for activity in activities {
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            guard category == .distracting else { continue }

            distractionTime[activity.appName, default: 0] += activity.durationSeconds
        }

        if let biggestDistraction = distractionTime.max(by: { $0.value < $1.value }) {
            dailyScore.setBiggestDistraction(biggestDistraction.key)
        }
    }
}
