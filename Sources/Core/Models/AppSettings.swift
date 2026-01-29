import Foundation
import SwiftData

public enum MenuBarClickBehavior: String, Codable {
    case showPopover = "Show Popover"
    case openApp = "Open App"
}

@Model
public final class AppSettings {
    public var isTrackingEnabled: Bool
    public var defaultCategoryForNewApps: CategoryType
    public var trackingStartTime: Date?
    public var lastPausedTime: Date?
    public var watchedRepositories: [String]
    public var gitScanFrequencyHours: Int
    public var workspacePath: String?
    public var autoScanEnabled: Bool
    public var lastGitScanTime: Date?
    public var showInDock: Bool
    public var showInMenuBar: Bool
    public var menuBarClickBehavior: MenuBarClickBehavior

    public init() {
        self.isTrackingEnabled = true
        self.defaultCategoryForNewApps = .neutral
        self.trackingStartTime = Date()
        self.lastPausedTime = nil
        self.watchedRepositories = []
        self.gitScanFrequencyHours = 24
        self.workspacePath = nil
        self.autoScanEnabled = false
        self.lastGitScanTime = nil
        self.showInDock = true
        self.showInMenuBar = true
        self.menuBarClickBehavior = .showPopover
    }

    public func pauseTracking() {
        isTrackingEnabled = false
        lastPausedTime = Date()
    }

    public func resumeTracking() {
        isTrackingEnabled = true
        lastPausedTime = nil
    }
}
