import Testing
import Foundation
import SwiftData
@testable import KafeelCore

@MainActor
struct PersistenceServiceTests {

    // MARK: - Test Helpers

    private func createTestService() throws -> PersistenceService {
        // Note: For true unit tests, we'd want to use in-memory storage
        // For now, we'll use the shared instance and clean up after each test
        return PersistenceService.shared
    }

    private func cleanupTestData() async throws {
        let service = PersistenceService.shared
        try await service.deleteAllData()
    }

    // MARK: - Activity Log Tests

    @Test("Save and fetch activity log")
    func testSaveAndFetchActivityLog() async throws {
        try await cleanupTestData()
        let service = try createTestService()

        // Create a test activity
        let activity = ActivityLog(
            appBundleIdentifier: "com.test.app",
            appName: "Test App",
            windowTitle: "Test Window",
            startTime: Date()
        )
        activity.finalize()

        // Save the activity
        try service.saveActivityLog(activity)

        // Fetch activities for today
        let activities = try service.fetchActivities(for: Date())

        #expect(activities.count >= 1)
        let savedActivity = activities.first { $0.appBundleIdentifier == "com.test.app" }
        #expect(savedActivity != nil)
        #expect(savedActivity?.appName == "Test App")
        #expect(savedActivity?.windowTitle == "Test Window")
    }

    @Test("Fetch activities for specific date")
    func testFetchActivitiesForDate() async throws {
        try await cleanupTestData()
        let service = try createTestService()

        // Create activities for today and yesterday
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let todayActivity = ActivityLog(
            appBundleIdentifier: "com.test.today",
            appName: "Today App",
            startTime: today
        )
        todayActivity.finalize()

        let yesterdayActivity = ActivityLog(
            appBundleIdentifier: "com.test.yesterday",
            appName: "Yesterday App",
            startTime: yesterday
        )
        yesterdayActivity.finalize()

        try service.saveActivityLog(todayActivity)
        try service.saveActivityLog(yesterdayActivity)

        // Fetch today's activities
        let todayActivities = try service.fetchActivities(for: today)
        let todayBundleIds = todayActivities.map { $0.appBundleIdentifier }
        #expect(todayBundleIds.contains("com.test.today"))
        #expect(!todayBundleIds.contains("com.test.yesterday"))

        // Fetch yesterday's activities
        let yesterdayActivities = try service.fetchActivities(for: yesterday)
        let yesterdayBundleIds = yesterdayActivities.map { $0.appBundleIdentifier }
        #expect(yesterdayBundleIds.contains("com.test.yesterday"))
        #expect(!yesterdayBundleIds.contains("com.test.today"))
    }

    @Test("Fetch activities in date range")
    func testFetchActivitiesInDateRange() async throws {
        try await cleanupTestData()
        let service = try createTestService()

        let today = Date()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        // Create activities across multiple days
        let oldActivity = ActivityLog(
            appBundleIdentifier: "com.test.old",
            appName: "Old App",
            startTime: twoDaysAgo
        )
        oldActivity.finalize()

        let recentActivity = ActivityLog(
            appBundleIdentifier: "com.test.recent",
            appName: "Recent App",
            startTime: oneDayAgo
        )
        recentActivity.finalize()

        try service.saveActivityLog(oldActivity)
        try service.saveActivityLog(recentActivity)

        // Fetch activities in range
        let activities = try service.fetchActivities(from: twoDaysAgo, to: today)
        let bundleIds = activities.map { $0.appBundleIdentifier }

        #expect(bundleIds.contains("com.test.old"))
        #expect(bundleIds.contains("com.test.recent"))
    }

    // MARK: - Category Tests

    @Test("Get and set app category")
    func testGetAndSetCategory() async throws {
        try await cleanupTestData()
        let service = try createTestService()

        let bundleId = "com.test.newapp"
        let appName = "Test New App"

        // Initially no category
        let initialCategory = service.getCategory(for: bundleId)
        #expect(initialCategory == nil)

        // Set category
        try service.setCategory(.productive, for: bundleId, appName: appName)

        // Verify category was set
        let category = service.getCategory(for: bundleId)
        #expect(category != nil)
        #expect(category?.category == .productive)
        #expect(category?.appName == appName)
        #expect(category?.isDefault == false)
    }

    @Test("Update existing category")
    func testUpdateCategory() async throws {
        try await cleanupTestData()
        let service = try createTestService()

        let bundleId = "com.test.updateapp"
        let appName = "Test Update App"

        // Set initial category
        try service.setCategory(.productive, for: bundleId, appName: appName)

        // Update to different category
        try service.setCategory(.distracting, for: bundleId, appName: appName)

        // Verify category was updated
        let category = service.getCategory(for: bundleId)
        #expect(category?.category == .distracting)
        #expect(category?.isDefault == false)
    }

    @Test("Get default category")
    func testGetDefaultCategory() async throws {
        // Note: Default categories are only initialized on first run
        // Since we clean up data in other tests, we need to recreate them
        // For this test, we'll just verify the pattern works
        let service = try createTestService()

        // Add a test default category
        let testCategory = AppCategory(
            bundleIdentifier: "com.test.default",
            appName: "Test Default App",
            category: .productive,
            isDefault: true
        )
        service.context.insert(testCategory)
        try service.context.save()

        // Verify we can retrieve it
        let retrieved = service.getCategory(for: "com.test.default")
        #expect(retrieved != nil)
        #expect(retrieved?.category == .productive)
        #expect(retrieved?.isDefault == true)
    }

    // MARK: - Settings Tests

    @Test("Get or create settings")
    func testGetOrCreateSettings() async throws {
        try await cleanupTestData()
        let service = try createTestService()

        // First call should create settings
        let settings1 = try service.getOrCreateSettings()
        #expect(settings1.isTrackingEnabled == true)
        #expect(settings1.defaultCategoryForNewApps == .neutral)

        // Second call should return same settings
        let settings2 = try service.getOrCreateSettings()
        #expect(settings2.isTrackingEnabled == settings1.isTrackingEnabled)
    }

    @Test("Settings pause and resume")
    func testSettingsPauseAndResume() async throws {
        try await cleanupTestData()
        let service = try createTestService()

        let settings = try service.getOrCreateSettings()

        // Initially enabled
        #expect(settings.isTrackingEnabled == true)
        #expect(settings.lastPausedTime == nil)

        // Pause tracking
        settings.pauseTracking()
        #expect(settings.isTrackingEnabled == false)
        #expect(settings.lastPausedTime != nil)

        // Resume tracking
        settings.resumeTracking()
        #expect(settings.isTrackingEnabled == true)
        #expect(settings.lastPausedTime == nil)
    }

    // MARK: - Data Management Tests

    @Test("Delete all data")
    func testDeleteAllData() async throws {
        let service = try createTestService()

        // Add some test data
        let activity = ActivityLog(
            appBundleIdentifier: "com.test.delete",
            appName: "Delete Test",
            startTime: Date()
        )
        activity.finalize()
        try service.saveActivityLog(activity)

        try service.setCategory(.productive, for: "com.test.delete", appName: "Delete Test")

        // Delete all data
        try await service.deleteAllData()

        // Verify data is deleted
        let activities = try service.fetchActivities(for: Date())
        let testActivities = activities.filter { $0.appBundleIdentifier == "com.test.delete" }
        #expect(testActivities.isEmpty)
    }
}
