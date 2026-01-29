import Foundation
import SwiftData

/// Source of meeting detection
public enum MeetingSource: String, Codable, CaseIterable, Sendable {
    case googleMeet = "google_meet"
    case calendar = "calendar"
    case zoom = "zoom"
    case teams = "teams"
    case webex = "webex"
    case manual = "manual"

    public var displayName: String {
        switch self {
        case .googleMeet: return "Google Meet"
        case .calendar: return "Calendar"
        case .zoom: return "Zoom"
        case .teams: return "Microsoft Teams"
        case .webex: return "Webex"
        case .manual: return "Manual"
        }
    }

    public var icon: String {
        switch self {
        case .googleMeet: return "video.fill"
        case .calendar: return "calendar"
        case .zoom: return "video.circle.fill"
        case .teams: return "person.3.fill"
        case .webex: return "video.badge.checkmark"
        case .manual: return "hand.tap.fill"
        }
    }

    /// Browser window title patterns for auto-detection
    public var browserPatterns: [String] {
        switch self {
        case .googleMeet:
            return ["meet.google.com", "Google Meet"]
        case .zoom:
            return ["zoom.us/j/", "Zoom Meeting"]
        case .teams:
            return ["teams.microsoft.com", "Microsoft Teams"]
        case .webex:
            return ["webex.com", "Webex"]
        default:
            return []
        }
    }
}

/// Detected meeting session (via browser or calendar)
@Model
public final class MeetingSession {
    public var id: UUID
    public var title: String?
    public var sourceRawValue: String
    public var startTime: Date
    public var endTime: Date?
    public var durationSeconds: Int
    public var calendarEventId: String?
    public var browserWindowTitle: String?
    public var isActive: Bool

    public var source: MeetingSource {
        MeetingSource(rawValue: sourceRawValue) ?? .manual
    }

    // MARK: - Computed Properties

    public var duration: TimeInterval {
        guard let end = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return end.timeIntervalSince(startTime)
    }

    public var formattedDuration: String {
        let totalSeconds = durationSeconds > 0 ? durationSeconds : Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    public var displayTitle: String {
        title ?? "Meeting"
    }

    // MARK: - Initialization

    public init(
        source: MeetingSource,
        title: String? = nil,
        startTime: Date = Date(),
        calendarEventId: String? = nil,
        browserWindowTitle: String? = nil
    ) {
        self.id = UUID()
        self.sourceRawValue = source.rawValue
        self.title = title
        self.startTime = startTime
        self.endTime = nil
        self.durationSeconds = 0
        self.calendarEventId = calendarEventId
        self.browserWindowTitle = browserWindowTitle
        self.isActive = true
    }

    // MARK: - Session Management

    public func endSession() {
        guard isActive else { return }
        self.endTime = Date()
        self.durationSeconds = Int(duration)
        self.isActive = false
    }

    public func updateDuration() {
        if isActive {
            self.durationSeconds = Int(duration)
        }
    }

    // MARK: - Static Detection Helpers

    /// Check if a browser window title indicates a meeting
    public static func detectMeetingSource(from windowTitle: String?) -> MeetingSource? {
        guard let title = windowTitle?.lowercased() else { return nil }

        for source in MeetingSource.allCases {
            for pattern in source.browserPatterns {
                if title.contains(pattern.lowercased()) {
                    return source
                }
            }
        }

        return nil
    }

    /// Check if a bundle identifier is a dedicated meeting app
    public static func isMeetingApp(bundleIdentifier: String) -> MeetingSource? {
        let meetingApps: [String: MeetingSource] = [
            "us.zoom.xos": .zoom,
            "com.microsoft.teams": .teams,
            "com.cisco.webex.meetings": .webex
        ]

        return meetingApps[bundleIdentifier]
    }

    /// Bundle identifiers of browsers that might show meeting content
    public static let browserBundleIds: Set<String> = [
        "com.google.Chrome",
        "com.apple.Safari",
        "com.microsoft.edgemac",
        "org.mozilla.firefox",
        "com.brave.Browser",
        "com.operasoftware.Opera"
    ]

    /// Check if a bundle identifier is a browser (needs window title check for meetings)
    public static func isBrowser(bundleIdentifier: String) -> Bool {
        browserBundleIds.contains(bundleIdentifier)
    }
}
