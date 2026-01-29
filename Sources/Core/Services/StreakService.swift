import Foundation
import SwiftData

/// Result of processing a day for streak tracking
public struct StreakResult {
    public let previousStreak: Int
    public let currentStreak: Int
    public let wasStreakExtended: Bool
    public let wasStreakBroken: Bool
    public let shieldUsed: Bool
    public let xpBonus: Int

    public init(
        previousStreak: Int,
        currentStreak: Int,
        wasStreakExtended: Bool,
        wasStreakBroken: Bool,
        shieldUsed: Bool,
        xpBonus: Int
    ) {
        self.previousStreak = previousStreak
        self.currentStreak = currentStreak
        self.wasStreakExtended = wasStreakExtended
        self.wasStreakBroken = wasStreakBroken
        self.shieldUsed = shieldUsed
        self.xpBonus = xpBonus
    }
}

/// Service for managing user streaks and shield mechanics
@MainActor
public final class StreakService {
    private let persistenceService: PersistenceService

    public init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }

    // MARK: - Public API

    /// Process a day's score and update streak accordingly
    /// - Parameters:
    ///   - date: The date to process
    ///   - focusScore: The focus score for that day
    /// - Returns: Result containing streak changes and XP bonuses
    public func processDay(date: Date, focusScore: Double) throws -> StreakResult {
        let streak = try persistenceService.getOrCreateStreak()
        let previousStreakDays = streak.currentStreakDays
        var shieldUsed = false
        var xpBonus = 0

        let isProductiveDay = focusScore >= 60.0

        if isProductiveDay {
            // Record productive day and get milestone XP bonus
            xpBonus = streak.recordProductiveDay(date: date)
            try persistenceService.save()

            return StreakResult(
                previousStreak: previousStreakDays,
                currentStreak: streak.currentStreakDays,
                wasStreakExtended: streak.currentStreakDays > previousStreakDays,
                wasStreakBroken: false,
                shieldUsed: false,
                xpBonus: xpBonus
            )
        } else {
            // Check if we need to use a shield or break the streak
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: date)

            guard let lastProductiveDate = streak.lastProductiveDate else {
                // No streak to break
                return StreakResult(
                    previousStreak: 0,
                    currentStreak: 0,
                    wasStreakExtended: false,
                    wasStreakBroken: false,
                    shieldUsed: false,
                    xpBonus: 0
                )
            }

            let lastDay = calendar.startOfDay(for: lastProductiveDate)
            guard let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day else {
                return StreakResult(
                    previousStreak: previousStreakDays,
                    currentStreak: streak.currentStreakDays,
                    wasStreakExtended: false,
                    wasStreakBroken: false,
                    shieldUsed: false,
                    xpBonus: 0
                )
            }

            // If this is today and we missed yesterday, try to use a shield
            if daysSince == 2 && streak.streakShields > 0 && streak.currentStreakDays > 0 {
                // Use shield to protect streak
                streak.streakShields -= 1
                streak.lastUpdated = Date()
                shieldUsed = true
                try persistenceService.save()

                return StreakResult(
                    previousStreak: previousStreakDays,
                    currentStreak: streak.currentStreakDays,
                    wasStreakExtended: false,
                    wasStreakBroken: false,
                    shieldUsed: true,
                    xpBonus: 0
                )
            }

            // Record unproductive day - might break streak
            let streakBroken = streak.recordUnproductiveDay(date: date)
            try persistenceService.save()

            return StreakResult(
                previousStreak: previousStreakDays,
                currentStreak: streak.currentStreakDays,
                wasStreakExtended: false,
                wasStreakBroken: streakBroken,
                shieldUsed: false,
                xpBonus: 0
            )
        }
    }

    /// Get the current streak information
    /// - Returns: The current Streak object
    public func getCurrentStreak() throws -> Streak {
        try persistenceService.getOrCreateStreak()
    }

    /// Manually use a shield to protect the streak
    /// - Returns: True if shield was successfully used, false if no shields available
    public func useShield() throws -> Bool {
        let streak = try persistenceService.getOrCreateStreak()
        let success = streak.useShield()
        if success {
            try persistenceService.save()
        }
        return success
    }
}
