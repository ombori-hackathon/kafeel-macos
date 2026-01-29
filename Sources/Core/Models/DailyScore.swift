import Foundation
import SwiftData

/// Daily aggregated metrics and XP earned for a single day
@Model
public final class DailyScore {
    @Attribute(.unique) public var date: Date
    public var focusScore: Double
    public var productiveSeconds: Int
    public var distractingSeconds: Int
    public var neutralSeconds: Int
    public var meetingSeconds: Int
    public var totalSeconds: Int
    public var switchCount: Int
    public var xpEarned: Int
    public var isProductiveDay: Bool
    public var peakHourStart: Int?
    public var peakHourEnd: Int?
    public var biggestDistraction: String?
    public var createdAt: Date

    // MARK: - Computed Properties

    public var productivePercentage: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(productiveSeconds) / Double(totalSeconds) * 100
    }

    public var distractingPercentage: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(distractingSeconds) / Double(totalSeconds) * 100
    }

    public var meetingPercentage: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(meetingSeconds) / Double(totalSeconds) * 100
    }

    public var formattedProductiveTime: String {
        formatDuration(productiveSeconds)
    }

    public var formattedTotalTime: String {
        formatDuration(totalSeconds)
    }

    public var formattedMeetingTime: String {
        formatDuration(meetingSeconds)
    }

    public var peakHoursDescription: String? {
        guard let start = peakHourStart, let end = peakHourEnd else { return nil }
        let startFormatted = String(format: "%02d:00", start)
        let endFormatted = String(format: "%02d:00", end)
        return "\(startFormatted) - \(endFormatted)"
    }

    // MARK: - Initialization

    public init(
        date: Date,
        focusScore: Double = 0,
        productiveSeconds: Int = 0,
        distractingSeconds: Int = 0,
        neutralSeconds: Int = 0,
        meetingSeconds: Int = 0,
        totalSeconds: Int = 0,
        switchCount: Int = 0,
        xpEarned: Int = 0
    ) {
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
        self.focusScore = focusScore
        self.productiveSeconds = productiveSeconds
        self.distractingSeconds = distractingSeconds
        self.neutralSeconds = neutralSeconds
        self.meetingSeconds = meetingSeconds
        self.totalSeconds = totalSeconds
        self.switchCount = switchCount
        self.xpEarned = xpEarned
        self.isProductiveDay = focusScore >= 60
        self.createdAt = Date()
    }

    // MARK: - Update Methods

    public func updateFromStats(
        focusScore: Double,
        productiveSeconds: Int,
        distractingSeconds: Int,
        neutralSeconds: Int,
        meetingSeconds: Int,
        switchCount: Int
    ) {
        self.focusScore = focusScore
        self.productiveSeconds = productiveSeconds
        self.distractingSeconds = distractingSeconds
        self.neutralSeconds = neutralSeconds
        self.meetingSeconds = meetingSeconds
        self.totalSeconds = productiveSeconds + distractingSeconds + neutralSeconds + meetingSeconds
        self.switchCount = switchCount
        self.isProductiveDay = focusScore >= 60
    }

    public func setXPEarned(_ xp: Int) {
        self.xpEarned = xp
    }

    public func setPeakHours(start: Int, end: Int) {
        self.peakHourStart = start
        self.peakHourEnd = end
    }

    public func setBiggestDistraction(_ appName: String) {
        self.biggestDistraction = appName
    }

    // MARK: - Private Helpers

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
