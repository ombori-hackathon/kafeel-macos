import EventKit
import Foundation

/// Service for accessing Apple Calendar events using EventKit
///
/// IMPORTANT: Add to Info.plist:
/// <key>NSCalendarsUsageDescription</key>
/// <string>Kafeel needs access to your calendar to show meeting times and calculate focus time.</string>
@MainActor
public final class CalendarService {
    private let eventStore = EKEventStore()
    private var hasAccess = false

    public static let shared = CalendarService()

    private init() {}

    /// Request full access to calendar events
    /// Returns true if access is granted, false otherwise
    public func requestAccess() async -> Bool {
        let status = authorizationStatus
        print("CalendarService: Requesting calendar access...")
        print("CalendarService: Current status: \(status.rawValue)")

        // Check if already authorized
        switch status {
        case .fullAccess, .authorized:
            print("CalendarService: Already have access")
            hasAccess = true
            return true
        case .denied, .restricted:
            print("CalendarService: Access denied or restricted")
            hasAccess = false
            return false
        case .notDetermined, .writeOnly:
            // Need to request
            break
        @unknown default:
            print("CalendarService: Unknown authorization status")
            break
        }

        do {
            // Use requestFullAccessToEvents for macOS 14+
            let granted = try await eventStore.requestFullAccessToEvents()
            hasAccess = granted
            print("CalendarService: Access granted = \(granted)")
            print("CalendarService: New status: \(authorizationStatus.rawValue)")
            return granted
        } catch {
            print("CalendarService: Error requesting access: \(error)")
            print("CalendarService: Error details: \(error.localizedDescription)")
            hasAccess = false
            return false
        }
    }

    /// Check current authorization status
    public var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    /// Fetch all events in a date range
    /// Returns empty array if access not granted
    public func fetchEvents(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        guard hasAccess || authorizationStatus == .fullAccess else {
            return []
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil // nil = all calendars
        )

        let ekEvents = eventStore.events(matching: predicate)
        return ekEvents.map { CalendarEvent(from: $0) }
    }

    /// Get total meeting time (in seconds) for a specific date
    /// Only counts non-all-day events
    public func getMeetingTime(for date: Date) -> TimeInterval {
        let events = fetchEventsForDay(date)
        return events
            .filter { !$0.isAllDay }
            .reduce(0) { $0 + $1.duration }
    }

    /// Get focus time (time not in meetings) for a specific date
    /// Calculated as: work hours (8 AM - 6 PM) minus meeting time
    public func getFocusTime(for date: Date) -> TimeInterval {
        let workHours: TimeInterval = 10 * 3600 // 10 hours (8 AM - 6 PM)
        let meetingTime = getMeetingTime(for: date)
        return max(0, workHours - meetingTime)
    }

    /// Get events for a specific day (midnight to midnight)
    public func fetchEventsForDay(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        return fetchEvents(from: startOfDay, to: endOfDay)
    }

    /// Get events for the current week (Monday - Sunday)
    public func fetchEventsForWeek(containing date: Date = Date()) -> [CalendarEvent] {
        let calendar = Calendar.current
        var weekStart = date
        var interval: TimeInterval = 0

        guard calendar.dateInterval(of: .weekOfYear, start: &weekStart, interval: &interval, for: date) else {
            return []
        }

        let weekEnd = weekStart.addingTimeInterval(interval)
        return fetchEvents(from: weekStart, to: weekEnd)
    }

    /// Get events for the current month
    public func fetchEventsForMonth(containing date: Date = Date()) -> [CalendarEvent] {
        let calendar = Calendar.current
        var monthStart = date
        var interval: TimeInterval = 0

        guard calendar.dateInterval(of: .month, start: &monthStart, interval: &interval, for: date) else {
            return []
        }

        let monthEnd = monthStart.addingTimeInterval(interval)
        return fetchEvents(from: monthStart, to: monthEnd)
    }

    /// Get meeting statistics for a date range
    public func getMeetingStats(from startDate: Date, to endDate: Date) -> MeetingStats {
        let events = fetchEvents(from: startDate, to: endDate)
            .filter { !$0.isAllDay }

        let totalDuration = events.reduce(0) { $0 + $1.duration }
        let averageDuration = events.isEmpty ? 0 : totalDuration / TimeInterval(events.count)

        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1

        // Calculate work hours (10 hours per day)
        let totalWorkTime = TimeInterval(max(1, days)) * 10 * 3600
        let meetingPercentage = totalWorkTime > 0 ? (totalDuration / totalWorkTime) * 100 : 0

        return MeetingStats(
            totalMeetingTime: totalDuration,
            averageMeetingDuration: averageDuration,
            meetingCount: events.count,
            meetingPercentage: meetingPercentage,
            focusTime: max(0, totalWorkTime - totalDuration)
        )
    }

    /// Get the busiest day of the week in a date range
    public func getBusiestDay(from startDate: Date, to endDate: Date) -> (day: String, duration: TimeInterval)? {
        let calendar = Calendar.current
        var dayDurations: [Int: TimeInterval] = [:]

        let events = fetchEvents(from: startDate, to: endDate)
            .filter { !$0.isAllDay }

        for event in events {
            let weekday = calendar.component(.weekday, from: event.startDate)
            dayDurations[weekday, default: 0] += event.duration
        }

        guard let busiestWeekday = dayDurations.max(by: { $0.value < $1.value }) else {
            return nil
        }

        let dayName = calendar.weekdaySymbols[busiestWeekday.key - 1]
        return (dayName, busiestWeekday.value)
    }
}

/// Meeting statistics for a date range
public struct MeetingStats {
    public let totalMeetingTime: TimeInterval
    public let averageMeetingDuration: TimeInterval
    public let meetingCount: Int
    public let meetingPercentage: Double
    public let focusTime: TimeInterval

    public init(
        totalMeetingTime: TimeInterval,
        averageMeetingDuration: TimeInterval,
        meetingCount: Int,
        meetingPercentage: Double,
        focusTime: TimeInterval
    ) {
        self.totalMeetingTime = totalMeetingTime
        self.averageMeetingDuration = averageMeetingDuration
        self.meetingCount = meetingCount
        self.meetingPercentage = meetingPercentage
        self.focusTime = focusTime
    }

    public var formattedTotalTime: String {
        formatDuration(totalMeetingTime)
    }

    public var formattedAverageDuration: String {
        formatDuration(averageMeetingDuration)
    }

    public var formattedFocusTime: String {
        formatDuration(focusTime)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}
