import Foundation
import SwiftData

@Model
public final class ActivityLog {
    public var id: UUID
    public var appBundleIdentifier: String
    public var appName: String
    public var windowTitle: String?
    public var startTime: Date
    public var endTime: Date?
    public var durationSeconds: Int

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
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    public init(
        appBundleIdentifier: String,
        appName: String,
        windowTitle: String? = nil,
        startTime: Date = Date()
    ) {
        self.id = UUID()
        self.appBundleIdentifier = appBundleIdentifier
        self.appName = appName
        self.windowTitle = windowTitle
        self.startTime = startTime
        self.endTime = nil
        self.durationSeconds = 0
    }

    public func finalize() {
        self.endTime = Date()
        self.durationSeconds = Int(duration)
    }
}
