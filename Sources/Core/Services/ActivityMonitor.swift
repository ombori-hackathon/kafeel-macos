import Foundation
import AppKit
import Observation

@MainActor
@Observable
public final class ActivityMonitor {
    public private(set) var isMonitoring = false
    public private(set) var currentApp: String?
    public private(set) var currentActivity: ActivityLog?

    private let persistenceService: PersistenceService
    private let minimumActivityDuration: TimeInterval = 2.0

    // Optional Flow Score integration
    public var flowScoreEngine: FlowScoreEngine?
    public var meetingDetector: MeetingDetector?

    private var appActivationObserver: NSObjectProtocol?
    private var screenLockObserver: NSObjectProtocol?
    private var screenUnlockObserver: NSObjectProtocol?

    public init(
        persistenceService: PersistenceService = .shared,
        flowScoreEngine: FlowScoreEngine? = nil,
        meetingDetector: MeetingDetector? = nil
    ) {
        self.persistenceService = persistenceService
        self.flowScoreEngine = flowScoreEngine
        self.meetingDetector = meetingDetector
    }

    deinit {
        // Cannot call @MainActor methods from deinit
        // Observers will be cleaned up automatically
    }

    // MARK: - Public Methods

    public func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        setupNotificationObservers()
        trackFrontmostApp()

        print("ActivityMonitor: Started monitoring")
    }

    public func stopMonitoring() {
        guard isMonitoring else { return }

        isMonitoring = false
        removeNotificationObservers()
        finalizeCurrentActivity()

        print("ActivityMonitor: Stopped monitoring")
    }

    // MARK: - Private Methods

    private func setupNotificationObservers() {
        // Monitor app activation
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppActivation()
        }

        // Monitor screen lock
        let dnc = DistributedNotificationCenter.default()

        screenLockObserver = dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenLock()
        }

        screenUnlockObserver = dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenUnlock()
        }
    }

    private func removeNotificationObservers() {
        if let observer = appActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            appActivationObserver = nil
        }

        let dnc = DistributedNotificationCenter.default()

        if let observer = screenLockObserver {
            dnc.removeObserver(observer)
            screenLockObserver = nil
        }

        if let observer = screenUnlockObserver {
            dnc.removeObserver(observer)
            screenUnlockObserver = nil
        }
    }

    private func trackFrontmostApp() {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return
        }

        let bundleId = app.bundleIdentifier ?? "unknown"
        let appName = app.localizedName ?? "Unknown App"

        // Get window title if available
        let windowTitle: String? = nil // AXUIElement would be needed for this

        // Check for meeting detection
        if let detector = meetingDetector {
            do {
                try detector.checkForMeeting(bundleIdentifier: bundleId, windowTitle: windowTitle)
            } catch {
                print("ActivityMonitor: Error checking for meeting: \(error)")
            }
        }

        // Finalize previous activity if exists
        finalizeCurrentActivity()

        // Create new activity
        let newActivity = ActivityLog(
            appBundleIdentifier: bundleId,
            appName: appName,
            windowTitle: windowTitle,
            startTime: Date()
        )

        currentActivity = newActivity
        currentApp = appName

        print("ActivityMonitor: Tracking \(appName) (\(bundleId))")
    }

    private func finalizeCurrentActivity() {
        guard let activity = currentActivity else {
            return
        }

        // Finalize the activity
        activity.finalize()

        // Only save if duration is above minimum threshold
        if activity.duration >= minimumActivityDuration {
            do {
                try persistenceService.saveActivityLog(activity)
                print("ActivityMonitor: Saved activity for \(activity.appName) - \(activity.formattedDuration)")

                // Process activity with FlowScoreEngine if available
                if let engine = flowScoreEngine {
                    let categories = getCategoryMappings()
                    try engine.processActivity(activity: activity, categories: categories)
                }
            } catch {
                print("ActivityMonitor: Error saving activity: \(error)")
            }
        } else {
            print("ActivityMonitor: Ignoring short activity (\(Int(activity.duration))s) for \(activity.appName)")
        }

        currentActivity = nil
    }

    // MARK: - Helper Methods

    private func getCategoryMappings() -> [String: CategoryType] {
        // Fetch category mappings from persistence service
        // For now, return empty dictionary - full implementation would query AppCategory records
        return [:]
    }

    // MARK: - Event Handlers

    private func handleAppActivation() {
        guard isMonitoring else { return }

        trackFrontmostApp()
    }

    private func handleScreenLock() {
        guard isMonitoring else { return }

        print("ActivityMonitor: Screen locked")
        finalizeCurrentActivity()
        currentApp = "Screen Locked"
    }

    private func handleScreenUnlock() {
        guard isMonitoring else { return }

        print("ActivityMonitor: Screen unlocked")
        trackFrontmostApp()
    }
}
