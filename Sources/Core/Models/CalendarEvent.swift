import Foundation
import SwiftUI
import EventKit

/// Wrapper for EKEvent with convenience properties for UI display
public struct CalendarEvent: Identifiable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let calendarColor: Color
    public let location: String?

    /// Duration in seconds
    public var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    /// Formatted time range (e.g., "9:00 AM - 10:30 AM")
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    /// Formatted duration (e.g., "1h 30m")
    public var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    /// Creates a CalendarEvent from an EKEvent
    public init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier
        self.title = ekEvent.title ?? "Untitled Event"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.location = ekEvent.location

        // Convert NSColor to SwiftUI Color
        if let cgColor = ekEvent.calendar.cgColor {
            #if os(macOS)
            self.calendarColor = Color(cgColor: cgColor)
            #else
            self.calendarColor = Color(cgColor: cgColor)
            #endif
        } else {
            self.calendarColor = .blue
        }
    }

    /// Manual initializer for testing
    public init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        calendarColor: Color = .blue,
        location: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarColor = calendarColor
        self.location = location
    }

    /// Check if event overlaps with a given date range
    public func overlaps(start: Date, end: Date) -> Bool {
        return startDate < end && endDate > start
    }

    /// Check if event is happening at a specific time
    public func isHappening(at date: Date) -> Bool {
        return date >= startDate && date < endDate
    }
}
