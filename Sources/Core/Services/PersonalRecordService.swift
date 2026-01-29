import Foundation
import SwiftData

/// Information about a record that was updated
public struct RecordUpdate {
    public let category: RecordCategory
    public let oldValue: Double
    public let newValue: Double

    public init(category: RecordCategory, oldValue: Double, newValue: Double) {
        self.category = category
        self.oldValue = oldValue
        self.newValue = newValue
    }

    public var improvement: Double {
        guard oldValue > 0 else { return 0 }
        return ((newValue - oldValue) / oldValue) * 100
    }

    public var formattedImprovement: String {
        let sign = improvement >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", improvement))%"
    }
}

/// Service for managing personal records and achievements
@MainActor
public final class PersonalRecordService {
    private let persistenceService: PersistenceService

    public init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }

    // MARK: - Public API

    /// Check and update all relevant personal records based on daily stats
    /// - Parameters:
    ///   - dailyScore: The daily score to evaluate
    ///   - streak: Current streak information
    ///   - userProfile: User profile with XP info
    /// - Returns: Array of records that were updated
    public func checkAndUpdateRecords(
        dailyScore: DailyScore,
        streak: Streak,
        userProfile: UserProfile
    ) throws -> [RecordUpdate] {
        var updates: [RecordUpdate] = []

        // Check best day score
        let bestDayRecord = try persistenceService.getOrCreateRecord(category: .bestDayScore)
        if dailyScore.focusScore > bestDayRecord.value {
            updates.append(RecordUpdate(
                category: .bestDayScore,
                oldValue: bestDayRecord.value,
                newValue: dailyScore.focusScore
            ))
            bestDayRecord.updateIfBetter(
                dailyScore.focusScore,
                details: "Score: \(String(format: "%.1f", dailyScore.focusScore))"
            )
        }

        // Check longest streak
        let longestStreakRecord = try persistenceService.getOrCreateRecord(category: .longestStreak)
        if Double(streak.longestStreakDays) > longestStreakRecord.value {
            updates.append(RecordUpdate(
                category: .longestStreak,
                oldValue: longestStreakRecord.value,
                newValue: Double(streak.longestStreakDays)
            ))
            longestStreakRecord.updateIfBetter(
                Double(streak.longestStreakDays),
                details: "\(streak.longestStreakDays) consecutive days"
            )
        }

        // Check longest focus session (most productive hours in a day)
        let longestFocusRecord = try persistenceService.getOrCreateRecord(category: .longestFocusSession)
        let productiveHours = Double(dailyScore.productiveSeconds)
        if productiveHours > longestFocusRecord.value {
            updates.append(RecordUpdate(
                category: .longestFocusSession,
                oldValue: longestFocusRecord.value,
                newValue: productiveHours
            ))
            longestFocusRecord.updateIfBetter(
                productiveHours,
                details: dailyScore.formattedProductiveTime
            )
        }

        // Check most productive day (total productive seconds)
        let mostProductiveRecord = try persistenceService.getOrCreateRecord(category: .mostProductiveDay)
        let totalProductive = Double(dailyScore.productiveSeconds)
        if totalProductive > mostProductiveRecord.value {
            updates.append(RecordUpdate(
                category: .mostProductiveDay,
                oldValue: mostProductiveRecord.value,
                newValue: totalProductive
            ))
            mostProductiveRecord.updateIfBetter(
                totalProductive,
                details: dailyScore.formattedProductiveTime
            )
        }

        // Check most productive hour (peak hour tracking)
        if let peakHour = dailyScore.peakHourStart {
            let mostProductiveHourRecord = try persistenceService.getOrCreateRecord(category: .mostProductiveHour)
            // Store the hour with the most activity - we could enhance this with actual time tracking
            // For now, just track if we have peak hours recorded
            if mostProductiveHourRecord.value == 0 {
                mostProductiveHourRecord.updateIfBetter(
                    Double(peakHour),
                    details: dailyScore.peakHoursDescription
                )
            }
        }

        // Check highest XP day
        let highestXPRecord = try persistenceService.getOrCreateRecord(category: .highestXPDay)
        if Double(dailyScore.xpEarned) > highestXPRecord.value {
            updates.append(RecordUpdate(
                category: .highestXPDay,
                oldValue: highestXPRecord.value,
                newValue: Double(dailyScore.xpEarned)
            ))
            highestXPRecord.updateIfBetter(
                Double(dailyScore.xpEarned),
                details: "\(dailyScore.xpEarned) XP earned"
            )
        }

        // Check best week score - calculate if we have 7 days
        try checkBestWeekScore(for: dailyScore.date, updates: &updates)

        // Save all changes
        if !updates.isEmpty {
            try persistenceService.save()
        }

        return updates
    }

    /// Get all personal records
    /// - Returns: Array of all PersonalRecord objects (creates missing ones if needed)
    public func getAllRecords() throws -> [PersonalRecord] {
        // Ensure all record categories exist
        for category in RecordCategory.allCases {
            _ = try persistenceService.getOrCreateRecord(category: category)
        }
        return try persistenceService.getAllRecords()
    }

    /// Get a specific personal record
    /// - Parameter category: The category of record to fetch
    /// - Returns: The PersonalRecord if it exists, nil otherwise
    public func getRecord(category: RecordCategory) throws -> PersonalRecord? {
        try persistenceService.getRecord(category: category)
    }

    // MARK: - Private Helpers

    private func checkBestWeekScore(for date: Date, updates: inout [RecordUpdate]) throws {
        let calendar = Calendar.current
        let weekStart = calendar.date(byAdding: .day, value: -6, to: date)!

        let scores = try persistenceService.fetchDailyScores(from: weekStart, to: date)

        // Only calculate if we have 7 days
        if scores.count >= 7 {
            let weekAverage = scores.reduce(0.0) { $0 + $1.focusScore } / Double(scores.count)

            let bestWeekRecord = try persistenceService.getOrCreateRecord(category: .bestWeekScore)
            if weekAverage > bestWeekRecord.value {
                updates.append(RecordUpdate(
                    category: .bestWeekScore,
                    oldValue: bestWeekRecord.value,
                    newValue: weekAverage
                ))

                let formatter = DateFormatter()
                formatter.dateStyle = .short
                let details = "Week of \(formatter.string(from: weekStart))"
                bestWeekRecord.updateIfBetter(weekAverage, details: details)
            }
        }
    }
}
