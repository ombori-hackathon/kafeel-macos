import Testing
import Foundation
@testable import KafeelCore

@Suite("FocusScoreCalculator Tests")
struct FocusScoreCalculatorTests {

    @Test("All productive time returns score 100")
    func testAllProductiveTime() {
        let activities = [
            createActivity(bundleId: "com.productive.app1", duration: 3600),
            createActivity(bundleId: "com.productive.app2", duration: 1800)
        ]

        let categories: [String: CategoryType] = [
            "com.productive.app1": .productive,
            "com.productive.app2": .productive
        ]

        let score = FocusScoreCalculator.calculate(
            activities: activities,
            categories: categories,
            defaultCategory: .neutral
        )

        #expect(score == 100.0)
    }

    @Test("All distracting time returns score 0")
    func testAllDistractingTime() {
        let activities = [
            createActivity(bundleId: "com.distracting.app1", duration: 3600),
            createActivity(bundleId: "com.distracting.app2", duration: 1800)
        ]

        let categories: [String: CategoryType] = [
            "com.distracting.app1": .distracting,
            "com.distracting.app2": .distracting
        ]

        let score = FocusScoreCalculator.calculate(
            activities: activities,
            categories: categories,
            defaultCategory: .neutral
        )

        #expect(score == 0.0)
    }

    @Test("Mixed time returns proportional score")
    func testMixedTime() {
        let activities = [
            createActivity(bundleId: "com.productive.app", duration: 3600),
            createActivity(bundleId: "com.distracting.app", duration: 3600)
        ]

        let categories: [String: CategoryType] = [
            "com.productive.app": .productive,
            "com.distracting.app": .distracting
        ]

        let score = FocusScoreCalculator.calculate(
            activities: activities,
            categories: categories,
            defaultCategory: .neutral
        )

        // 50% productive (weight 1.0) + 50% distracting (weight 0.0) = 50% score
        #expect(score == 50.0)
    }

    @Test("Neutral time weighted at 0.5")
    func testNeutralWeighting() {
        let activities = [
            createActivity(bundleId: "com.neutral.app", duration: 3600)
        ]

        let categories: [String: CategoryType] = [
            "com.neutral.app": .neutral
        ]

        let score = FocusScoreCalculator.calculate(
            activities: activities,
            categories: categories,
            defaultCategory: .neutral
        )

        // 100% neutral (weight 0.5) = 50% score
        #expect(score == 50.0)
    }

    @Test("Context switching penalty applied correctly")
    func testContextSwitchingPenalty() {
        // Create activities with excessive switching (20 switches in 1 hour)
        var activities: [ActivityLog] = []
        for i in 0..<20 {
            let bundleId = "com.app\(i % 2)" // Alternate between 2 apps
            activities.append(createActivity(bundleId: bundleId, duration: 180)) // 3 minutes each
        }

        let categories: [String: CategoryType] = [
            "com.app0": .productive,
            "com.app1": .productive
        ]

        let stats = FocusScoreCalculator.calculateStats(
            activities: activities,
            categories: categories,
            defaultCategory: .neutral
        )

        // Base score should be 100 (all productive)
        // But with 19 switches (first activity doesn't count as switch)
        // in 1 hour (3600 seconds), that's 19 switches/hour
        // Penalty = max(0, 19 - 10) * 0.5 = 4.5
        // Final score = 100 - 4.5 = 95.5

        #expect(stats.focusScore < 100.0)
        #expect(stats.focusScore > 90.0)
        #expect(stats.switchCount == 19) // 20 activities = 19 switches
    }

    @Test("Empty activities returns score 0")
    func testEmptyActivities() {
        let activities: [ActivityLog] = []
        let categories: [String: CategoryType] = [:]

        let score = FocusScoreCalculator.calculate(
            activities: activities,
            categories: categories,
            defaultCategory: .neutral
        )

        #expect(score == 0.0)
    }

    @Test("Score label for excellent score")
    func testExcellentLabel() {
        let (text, color) = FocusScoreCalculator.scoreLabel(for: 85.0)
        #expect(text == "Excellent")
        #expect(color == "green")
    }

    @Test("Score label for good score")
    func testGoodLabel() {
        let (text, color) = FocusScoreCalculator.scoreLabel(for: 70.0)
        #expect(text == "Good")
        #expect(color == "blue")
    }

    @Test("Score label for fair score")
    func testFairLabel() {
        let (text, color) = FocusScoreCalculator.scoreLabel(for: 50.0)
        #expect(text == "Fair")
        #expect(color == "yellow")
    }

    @Test("Score label for poor score")
    func testPoorLabel() {
        let (text, color) = FocusScoreCalculator.scoreLabel(for: 30.0)
        #expect(text == "Poor")
        #expect(color == "orange")
    }

    @Test("Score label for very poor score")
    func testVeryPoorLabel() {
        let (text, color) = FocusScoreCalculator.scoreLabel(for: 10.0)
        #expect(text == "Very Poor")
        #expect(color == "red")
    }

    @Test("Calculate stats returns correct breakdown")
    func testCalculateStats() {
        let activities = [
            createActivity(bundleId: "com.productive.app", duration: 3600),
            createActivity(bundleId: "com.distracting.app", duration: 1800),
            createActivity(bundleId: "com.neutral.app", duration: 600)
        ]

        let categories: [String: CategoryType] = [
            "com.productive.app": .productive,
            "com.distracting.app": .distracting,
            "com.neutral.app": .neutral
        ]

        let stats = FocusScoreCalculator.calculateStats(
            activities: activities,
            categories: categories,
            defaultCategory: .neutral
        )

        #expect(stats.productiveSeconds == 3600)
        #expect(stats.distractingSeconds == 1800)
        #expect(stats.neutralSeconds == 600)
        #expect(stats.totalSeconds == 6000)
        #expect(stats.switchCount == 2) // 3 activities = 2 switches
    }

    @Test("Default category applied for unknown apps")
    func testDefaultCategory() {
        let activities = [
            createActivity(bundleId: "com.unknown.app", duration: 3600)
        ]

        let categories: [String: CategoryType] = [:]

        let stats = FocusScoreCalculator.calculateStats(
            activities: activities,
            categories: categories,
            defaultCategory: .productive
        )

        // Should use default category (productive)
        #expect(stats.productiveSeconds == 3600)
        #expect(stats.distractingSeconds == 0)
        #expect(stats.neutralSeconds == 0)
        #expect(stats.focusScore == 100.0)
    }

    @Test("Score never exceeds 100")
    func testScoreMaxBound() {
        let activities = [
            createActivity(bundleId: "com.productive.app", duration: 7200)
        ]

        let categories: [String: CategoryType] = [
            "com.productive.app": .productive
        ]

        let score = FocusScoreCalculator.calculate(
            activities: activities,
            categories: categories,
            defaultCategory: .neutral
        )

        #expect(score <= 100.0)
    }

    @Test("Score never goes below 0")
    func testScoreMinBound() {
        // Create scenario with heavy penalty
        var activities: [ActivityLog] = []
        for i in 0..<100 {
            activities.append(createActivity(bundleId: "com.app\(i)", duration: 36)) // 1 hour total
        }

        let categories: [String: CategoryType] = [:]

        let score = FocusScoreCalculator.calculate(
            activities: activities,
            categories: categories,
            defaultCategory: .distracting
        )

        #expect(score >= 0.0)
    }

    // Helper function to create test activities
    private func createActivity(bundleId: String, duration: Int) -> ActivityLog {
        let activity = ActivityLog(
            appBundleIdentifier: bundleId,
            appName: "Test App",
            windowTitle: "Test Window",
            startTime: Date()
        )
        // Manually set duration for testing
        activity.durationSeconds = duration
        activity.endTime = Date().addingTimeInterval(TimeInterval(duration))
        return activity
    }
}
