import Foundation
import SwiftData
import Observation

@MainActor
@Observable
public final class MeetingDetector {
    public private(set) var isInMeeting: Bool = false
    public private(set) var currentMeeting: MeetingSession?

    private let persistenceService: PersistenceService

    public init(persistenceService: PersistenceService = .shared) {
        self.persistenceService = persistenceService
    }

    // MARK: - Public Methods

    /// Check for meeting based on bundle identifier and window title
    /// - Parameters:
    ///   - bundleIdentifier: The app's bundle identifier
    ///   - windowTitle: The window title (needed for browser-based meetings)
    public func checkForMeeting(bundleIdentifier: String, windowTitle: String?) throws {
        // First, check if it's a native meeting app
        if let meetingSource = MeetingSession.isMeetingApp(bundleIdentifier: bundleIdentifier) {
            try startMeeting(source: meetingSource, bundleIdentifier: bundleIdentifier, windowTitle: windowTitle)
            return
        }

        // If it's a browser, check the window title for meeting patterns
        if MeetingSession.isBrowser(bundleIdentifier: bundleIdentifier),
           let title = windowTitle,
           let meetingSource = MeetingSession.detectMeetingSource(from: title) {
            try startMeeting(source: meetingSource, bundleIdentifier: bundleIdentifier, windowTitle: title)
            return
        }

        // Not a meeting - end current meeting if one exists
        if isInMeeting {
            try endCurrentMeeting()
        }
    }

    /// End the current meeting session
    public func endCurrentMeeting() throws {
        guard let meeting = currentMeeting, meeting.isActive else {
            return
        }

        // Finalize the meeting
        meeting.endSession()

        // Save to persistence
        try persistenceService.save()

        print("MeetingDetector: Ended meeting - \(meeting.source.displayName) (\(meeting.formattedDuration))")

        // Update state
        isInMeeting = false
        currentMeeting = nil
    }

    /// Get total meeting seconds for today
    public func getTodayMeetingSeconds() throws -> Int {
        return try persistenceService.getTotalMeetingSeconds(for: Date())
    }

    // MARK: - Private Methods

    private func startMeeting(source: MeetingSource, bundleIdentifier: String, windowTitle: String?) throws {
        // If already in this meeting, just update duration
        if let meeting = currentMeeting,
           meeting.source == source,
           meeting.isActive {
            meeting.updateDuration()
            try persistenceService.save()
            return
        }

        // End previous meeting if exists
        if isInMeeting {
            try endCurrentMeeting()
        }

        // Create new meeting session
        let title = extractMeetingTitle(from: windowTitle, source: source)
        let newMeeting = MeetingSession(
            source: source,
            title: title,
            startTime: Date(),
            browserWindowTitle: windowTitle
        )

        // Save to persistence
        try persistenceService.saveMeetingSession(newMeeting)

        print("MeetingDetector: Started meeting - \(source.displayName)")

        // Update state
        currentMeeting = newMeeting
        isInMeeting = true
    }

    private func extractMeetingTitle(from windowTitle: String?, source: MeetingSource) -> String? {
        guard let title = windowTitle else { return nil }

        // Try to extract meeting name from browser title
        // Common patterns: "Meeting Name - Google Meet", "Zoom Meeting - ...", etc.
        let components = title.components(separatedBy: " - ")
        if components.count > 1 {
            let firstPart = components[0].trimmingCharacters(in: .whitespaces)
            // Don't return if it's just the service name
            if !firstPart.lowercased().contains(source.rawValue.replacingOccurrences(of: "_", with: " ")) {
                return firstPart
            }
        }

        return nil
    }
}
