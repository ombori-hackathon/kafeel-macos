import Testing
import Foundation
import SwiftData
@testable import KafeelCore

@MainActor
struct AchievementServiceTests {

    // MARK: - Test Helpers

    private func cleanupTestData() async throws {
        let service = PersistenceService.shared
        try await service.deleteAllData()
    }

    private func createTestDailyScore(
        date: Date,
        focusScore: Double,
        productiveSeconds: Int,
        meetingSeconds: Int = 0,
        xpEarned: Int = 0
    ) -> DailyScore {
        DailyScore(
            date: date,
            focusScore: focusScore,
            productiveSeconds: productiveSeconds,
            distractingSeconds: 0,
            neutralSeconds: 0,
            meetingSeconds: meetingSeconds,
            totalSeconds: productiveSeconds + meetingSeconds,
            switchCount: 0,
            xpEarned: xpEarned
        )
    }

    private func createTestActivity(
        bundleId: String,
        startTime: Date,
        durationSeconds: Int = 3600
    ) -> ActivityLog {
        let activity = ActivityLog(
            appBundleIdentifier: bundleId,
            appName: "Test App",
            startTime: startTime
        )
        activity.durationSeconds = durationSeconds
        activity.endTime = startTime.addingTimeInterval(Double(durationSeconds))
        return activity
    }

    // MARK: - Achievement Unlocking Tests

    @Test("First day achievement unlocks on first tracked day")
    func testFirstDayAchievement() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        let dailyScore = createTestDailyScore(date: Date(), focusScore: 70.0, productiveSeconds: 7200)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()
        profile.totalDaysTracked = 1

        let context = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: []
        )

        let unlocks = try service.checkAchievements(context: context)

        #expect(unlocks.contains { $0.type == .firstDay })
    }

    @Test("Week warrior achievement unlocks at 7-day streak")
    func testWeekWarriorAchievement() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        let dailyScore = createTestDailyScore(date: Date(), focusScore: 70.0, productiveSeconds: 7200)
        let streak = try persistenceService.getOrCreateStreak()
        streak.currentStreakDays = 7
        let profile = try persistenceService.getOrCreateUserProfile()

        let context = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: []
        )

        let unlocks = try service.checkAchievements(context: context)

        #expect(unlocks.contains { $0.type == .weekWarrior })
    }

    @Test("Streak master achievement unlocks at 30-day streak")
    func testStreakMasterAchievement() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        let dailyScore = createTestDailyScore(date: Date(), focusScore: 70.0, productiveSeconds: 7200)
        let streak = try persistenceService.getOrCreateStreak()
        streak.currentStreakDays = 30
        let profile = try persistenceService.getOrCreateUserProfile()

        let context = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: []
        )

        let unlocks = try service.checkAchievements(context: context)

        #expect(unlocks.contains { $0.type == .streakMaster })
    }

    @Test("Focus master achievement unlocks at score >= 90")
    func testFocusMasterAchievement() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        let dailyScore = createTestDailyScore(date: Date(), focusScore: 92.0, productiveSeconds: 10800)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()

        let context = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: []
        )

        let unlocks = try service.checkAchievements(context: context)

        #expect(unlocks.contains { $0.type == .focusMaster })
    }

    @Test("Meeting survivor achievement unlocks with 4+ hours meetings and score >= 60")
    func testMeetingSurvivorAchievement() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        let fourHours = 4 * 3600
        let dailyScore = createTestDailyScore(
            date: Date(),
            focusScore: 65.0,
            productiveSeconds: 7200,
            meetingSeconds: fourHours
        )
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()

        let context = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: []
        )

        let unlocks = try service.checkAchievements(context: context)

        #expect(unlocks.contains { $0.type == .meetingSurvivor })
    }

    @Test("Marathon achievement unlocks with 4+ hours productive work")
    func testMarathonAchievement() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        let fourHours = 4 * 3600
        let dailyScore = createTestDailyScore(date: Date(), focusScore: 80.0, productiveSeconds: fourHours + 600)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()

        let context = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: []
        )

        let unlocks = try service.checkAchievements(context: context)

        #expect(unlocks.contains { $0.type == .marathon })
    }

    @Test("Consistent performer achievement unlocks with 30+ days avg score >= 70")
    func testConsistentPerformerAchievement() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        let dailyScore = createTestDailyScore(date: Date(), focusScore: 75.0, productiveSeconds: 7200)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()
        profile.totalDaysTracked = 30
        profile.averageDailyScore = 72.0

        let context = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: []
        )

        let unlocks = try service.checkAchievements(context: context)

        #expect(unlocks.contains { $0.type == .consistentPerformer })
    }

    @Test("Early bird achievement unlocks with productive activity before 7 AM")
    func testEarlyBirdAchievement() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        // Create productive app category
        try persistenceService.setCategory(
            .productive,
            for: "com.test.productive",
            appName: "Productive App"
        )

        // Create activity at 6 AM
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sixAM = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: today)!

        let activity = createTestActivity(bundleId: "com.test.productive", startTime: sixAM)

        let dailyScore = createTestDailyScore(date: today, focusScore: 70.0, productiveSeconds: 7200)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()

        let context = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: [activity]
        )

        let unlocks = try service.checkAchievements(context: context)

        #expect(unlocks.contains { $0.type == .earlyBird })
    }

    @Test("Night owl achievement unlocks with productive activity after 10 PM")
    func testNightOwlAchievement() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        // Create productive app category
        try persistenceService.setCategory(
            .productive,
            for: "com.test.productive",
            appName: "Productive App"
        )

        // Create activity at 11 PM
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let elevenPM = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: today)!

        let activity = createTestActivity(bundleId: "com.test.productive", startTime: elevenPM)

        let dailyScore = createTestDailyScore(date: today, focusScore: 70.0, productiveSeconds: 7200)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()

        let context = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: [activity]
        )

        let unlocks = try service.checkAchievements(context: context)

        #expect(unlocks.contains { $0.type == .nightOwl })
    }

    // MARK: - Achievement Management Tests

    @Test("Get all achievements returns all types")
    func testGetAllAchievements() async throws {
        try await cleanupTestData()
        let service = AchievementService()

        let achievements = try service.getAllAchievements()

        #expect(achievements.count == AchievementType.allCases.count)
    }

    @Test("Get unlocked achievements returns only unlocked")
    func testGetUnlockedAchievements() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        // Unlock one achievement
        let achievement = try persistenceService.getOrCreateAchievement(type: .firstDay)
        achievement.unlock()
        try persistenceService.save()

        let unlocked = try service.getUnlockedAchievements()

        #expect(unlocked.count == 1)
        #expect(unlocked.first?.type == .firstDay)
    }

    @Test("Achievement does not unlock twice")
    func testAchievementDoesNotUnlockTwice() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        let dailyScore = createTestDailyScore(date: Date(), focusScore: 70.0, productiveSeconds: 7200)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()
        profile.totalDaysTracked = 1

        let context = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: []
        )

        // First check should unlock
        let unlocks1 = try service.checkAchievements(context: context)
        #expect(unlocks1.contains { $0.type == .firstDay })

        // Second check should not unlock again
        let unlocks2 = try service.checkAchievements(context: context)
        #expect(!unlocks2.contains { $0.type == .firstDay })
    }

    @Test("Repeatable achievement can unlock multiple times")
    func testRepeatableAchievement() async throws {
        try await cleanupTestData()
        let service = AchievementService()
        let persistenceService = PersistenceService.shared

        let fourHours = 4 * 3600
        let dailyScore = createTestDailyScore(date: Date(), focusScore: 80.0, productiveSeconds: fourHours + 600)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()

        let context = AchievementContext(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile,
            activities: []
        )

        // First unlock
        _ = try service.checkAchievements(context: context)

        // Get achievement and check times achieved
        let achievement = try persistenceService.getAchievement(type: .marathon)
        let firstCount = achievement?.timesAchieved ?? 0

        // Second unlock (repeatable)
        _ = try service.checkAchievements(context: context)

        // Verify it recorded again
        let achievement2 = try persistenceService.getAchievement(type: .marathon)
        #expect(achievement2?.timesAchieved ?? 0 > firstCount)
    }

    // MARK: - Achievement Unlock Info Tests

    @Test("Achievement unlock contains XP reward")
    func testAchievementUnlockXPReward() async throws {
        let unlock = AchievementUnlock(type: .firstDay, xpReward: 100)

        #expect(unlock.xpReward == 100)
        #expect(unlock.type == .firstDay)
    }
}
