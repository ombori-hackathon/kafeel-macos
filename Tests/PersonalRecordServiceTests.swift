import Testing
import Foundation
import SwiftData
@testable import KafeelCore

@MainActor
struct PersonalRecordServiceTests {

    // MARK: - Test Helpers

    private func cleanupTestData() async throws {
        let service = PersistenceService.shared
        try await service.deleteAllData()
    }

    private func createTestDailyScore(
        date: Date,
        focusScore: Double,
        productiveSeconds: Int,
        xpEarned: Int
    ) -> DailyScore {
        DailyScore(
            date: date,
            focusScore: focusScore,
            productiveSeconds: productiveSeconds,
            distractingSeconds: 0,
            neutralSeconds: 0,
            meetingSeconds: 0,
            totalSeconds: productiveSeconds,
            switchCount: 0,
            xpEarned: xpEarned
        )
    }

    // MARK: - Record Checking Tests

    @Test("Check and update best day score record")
    func testCheckAndUpdateBestDayScore() async throws {
        try await cleanupTestData()
        let service = PersonalRecordService()
        let persistenceService = PersistenceService.shared

        // Create test data
        let dailyScore = createTestDailyScore(date: Date(), focusScore: 85.0, productiveSeconds: 7200, xpEarned: 500)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()

        // Check for records - should create best day score
        let updates = try service.checkAndUpdateRecords(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile
        )

        #expect(updates.contains { $0.category == .bestDayScore })

        // Verify record was saved
        let record = try service.getRecord(category: .bestDayScore)
        #expect(record?.value == 85.0)
    }

    @Test("Check and update longest streak record")
    func testCheckAndUpdateLongestStreak() async throws {
        try await cleanupTestData()
        let service = PersonalRecordService()
        let persistenceService = PersistenceService.shared

        // Create test data with a 10-day streak
        let dailyScore = createTestDailyScore(date: Date(), focusScore: 70.0, productiveSeconds: 7200, xpEarned: 300)
        let streak = try persistenceService.getOrCreateStreak()
        streak.currentStreakDays = 10
        streak.longestStreakDays = 10
        let profile = try persistenceService.getOrCreateUserProfile()

        // Check for records
        let updates = try service.checkAndUpdateRecords(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile
        )

        #expect(updates.contains { $0.category == .longestStreak })

        // Verify record
        let record = try service.getRecord(category: .longestStreak)
        #expect(record?.value == 10.0)
    }

    @Test("Check and update highest XP day")
    func testCheckAndUpdateHighestXPDay() async throws {
        try await cleanupTestData()
        let service = PersonalRecordService()
        let persistenceService = PersistenceService.shared

        // Create test data with high XP
        let dailyScore = createTestDailyScore(date: Date(), focusScore: 90.0, productiveSeconds: 10800, xpEarned: 1500)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()

        // Check for records
        let updates = try service.checkAndUpdateRecords(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile
        )

        #expect(updates.contains { $0.category == .highestXPDay })

        // Verify record
        let record = try service.getRecord(category: .highestXPDay)
        #expect(record?.value == 1500.0)
    }

    @Test("No updates when records are not beaten")
    func testNoUpdatesWhenRecordsNotBeaten() async throws {
        try await cleanupTestData()
        let service = PersonalRecordService()
        let persistenceService = PersistenceService.shared

        // Set up existing records
        let dailyScore1 = createTestDailyScore(date: Date(), focusScore: 90.0, productiveSeconds: 10800, xpEarned: 1500)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()

        _ = try service.checkAndUpdateRecords(
            dailyScore: dailyScore1,
            streak: streak,
            userProfile: profile
        )

        // Try with lower scores
        let dailyScore2 = createTestDailyScore(date: Date(), focusScore: 70.0, productiveSeconds: 5400, xpEarned: 800)
        let updates = try service.checkAndUpdateRecords(
            dailyScore: dailyScore2,
            streak: streak,
            userProfile: profile
        )

        // Should have no updates (or only updates that are higher)
        let bestDayUpdate = updates.first { $0.category == .bestDayScore }
        #expect(bestDayUpdate == nil)
    }

    // MARK: - Get Records Tests

    @Test("Get all records")
    func testGetAllRecords() async throws {
        try await cleanupTestData()
        let service = PersonalRecordService()

        let records = try service.getAllRecords()

        // Should have all record categories initialized
        #expect(records.count == RecordCategory.allCases.count)
    }

    @Test("Get specific record")
    func testGetSpecificRecord() async throws {
        try await cleanupTestData()
        let service = PersonalRecordService()
        let persistenceService = PersistenceService.shared

        // Create and save a record
        let dailyScore = createTestDailyScore(date: Date(), focusScore: 85.0, productiveSeconds: 7200, xpEarned: 500)
        let streak = try persistenceService.getOrCreateStreak()
        let profile = try persistenceService.getOrCreateUserProfile()

        _ = try service.checkAndUpdateRecords(
            dailyScore: dailyScore,
            streak: streak,
            userProfile: profile
        )

        // Fetch specific record
        let record = try service.getRecord(category: .bestDayScore)

        #expect(record != nil)
        #expect(record?.value == 85.0)
        #expect(record?.category == .bestDayScore)
    }

    // MARK: - Record Update Info Tests

    @Test("Record update contains improvement percentage")
    func testRecordUpdateImprovement() async throws {
        let update = RecordUpdate(category: .bestDayScore, oldValue: 70.0, newValue: 85.0)

        #expect(update.improvement > 0)
        let expectedImprovement = ((85.0 - 70.0) / 70.0) * 100
        #expect(abs(update.improvement - expectedImprovement) < 0.1)
    }

    @Test("Record update formatted improvement")
    func testRecordUpdateFormattedImprovement() async throws {
        let update = RecordUpdate(category: .bestDayScore, oldValue: 70.0, newValue: 85.0)

        let formatted = update.formattedImprovement
        #expect(formatted.contains("+"))
        #expect(formatted.contains("%"))
    }
}
