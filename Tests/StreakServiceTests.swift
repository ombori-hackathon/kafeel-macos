import Testing
import Foundation
import SwiftData
@testable import KafeelCore

@MainActor
struct StreakServiceTests {

    // MARK: - Test Helpers

    private func cleanupTestData() async throws {
        let service = PersistenceService.shared
        try await service.deleteAllData()
    }

    // MARK: - Productive Day Tests

    @Test("Process productive day starts a streak")
    func testProcessProductiveDayStartsStreak() async throws {
        try await cleanupTestData()
        let service = StreakService()

        let result = try service.processDay(date: Date(), focusScore: 75.0)

        #expect(result.previousStreak == 0)
        #expect(result.currentStreak == 1)
        #expect(result.wasStreakExtended == true)
        #expect(result.wasStreakBroken == false)
        #expect(result.shieldUsed == false)
    }

    @Test("Process productive day extends existing streak")
    func testProcessProductiveDayExtendsStreak() async throws {
        try await cleanupTestData()
        let service = StreakService()
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Record yesterday as productive
        _ = try service.processDay(date: yesterday, focusScore: 70.0)

        // Record today as productive
        let result = try service.processDay(date: today, focusScore: 80.0)

        #expect(result.previousStreak == 1)
        #expect(result.currentStreak == 2)
        #expect(result.wasStreakExtended == true)
        #expect(result.wasStreakBroken == false)
    }

    @Test("Process productive day awards 7-day milestone")
    func testProcessProductiveDayAwards7DayMilestone() async throws {
        try await cleanupTestData()
        let service = StreakService()
        let calendar = Calendar.current
        let today = Date()

        // Build up a 6-day streak
        for i in (1...6).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            _ = try service.processDay(date: date, focusScore: 70.0)
        }

        // 7th day should award milestone
        let result = try service.processDay(date: today, focusScore: 70.0)

        #expect(result.currentStreak == 7)
        #expect(result.xpBonus > 0) // Should get XP bonus
    }

    // MARK: - Unproductive Day Tests

    @Test("Process unproductive day breaks streak")
    func testProcessUnproductiveDayBreaksStreak() async throws {
        try await cleanupTestData()
        let service = StreakService()
        let calendar = Calendar.current
        let today = Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        // Start a streak 2 days ago
        _ = try service.processDay(date: twoDaysAgo, focusScore: 70.0)

        // Skip yesterday, try today with low score
        let result = try service.processDay(date: today, focusScore: 40.0)

        #expect(result.wasStreakBroken == true)
        #expect(result.currentStreak == 0)
    }

    @Test("Process unproductive day uses shield automatically")
    func testProcessUnproductiveDayUsesShieldAutomatically() async throws {
        try await cleanupTestData()
        let service = StreakService()
        let persistenceService = PersistenceService.shared
        let calendar = Calendar.current
        let today = Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        // Start a streak 2 days ago
        _ = try service.processDay(date: twoDaysAgo, focusScore: 70.0)

        // Give the user a shield
        let streak = try persistenceService.getOrCreateStreak()
        streak.addShields(1)
        try persistenceService.save()

        // Skip yesterday, try today with low score - should use shield
        let result = try service.processDay(date: today, focusScore: 40.0)

        #expect(result.shieldUsed == true)
        #expect(result.wasStreakBroken == false)
        #expect(result.currentStreak == 1) // Streak preserved
    }

    // MARK: - Shield Management Tests

    @Test("Get current streak")
    func testGetCurrentStreak() async throws {
        try await cleanupTestData()
        let service = StreakService()

        // Start a streak
        _ = try service.processDay(date: Date(), focusScore: 70.0)

        let streak = try service.getCurrentStreak()

        #expect(streak.currentStreakDays == 1)
        #expect(streak.lastProductiveDate != nil)
    }

    @Test("Use shield manually")
    func testUseShieldManually() async throws {
        try await cleanupTestData()
        let service = StreakService()
        let persistenceService = PersistenceService.shared

        // Create a streak and add shields
        _ = try service.processDay(date: Date(), focusScore: 70.0)
        let streak = try persistenceService.getOrCreateStreak()
        streak.addShields(1)
        try persistenceService.save()

        // Use shield manually
        let success = try service.useShield()

        #expect(success == true)

        // Verify shield was consumed
        let updatedStreak = try service.getCurrentStreak()
        #expect(updatedStreak.streakShields == 0)
    }

    @Test("Use shield fails when none available")
    func testUseShieldFailsWhenNoneAvailable() async throws {
        try await cleanupTestData()
        let service = StreakService()

        // Try to use shield with no streak
        let success = try service.useShield()

        #expect(success == false)
    }

    // MARK: - Edge Cases

    @Test("Process same day twice does not duplicate")
    func testProcessSameDayTwiceDoesNotDuplicate() async throws {
        try await cleanupTestData()
        let service = StreakService()
        let today = Date()

        let result1 = try service.processDay(date: today, focusScore: 70.0)
        #expect(result1.currentStreak == 1)

        let result2 = try service.processDay(date: today, focusScore: 80.0)
        #expect(result2.currentStreak == 1) // Should not increment again
    }

    @Test("Streak boundary at 60 score")
    func testStreakBoundary60Score() async throws {
        try await cleanupTestData()
        let service = StreakService()
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let result1 = try service.processDay(date: yesterday, focusScore: 59.9)
        #expect(result1.currentStreak == 0)

        let result2 = try service.processDay(date: today, focusScore: 60.0)
        #expect(result2.currentStreak == 1)
    }
}
