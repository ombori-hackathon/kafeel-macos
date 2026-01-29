import SwiftUI
import AppKit
import KafeelCore

@MainActor
@Observable
class MenuBarManager {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    var appState: AppState?

    func setup(appState: AppState) {
        self.appState = appState

        // Use variable length to show score + icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            updateButtonDisplay(button: button, score: appState.focusScore, isTracking: appState.isTrackingEnabled)
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarPopoverView(appState: appState))
        self.popover = popover
    }

    @objc func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func updateIcon(isTracking: Bool) {
        guard let button = statusItem?.button else { return }
        let score = appState?.focusScore ?? 0
        updateButtonDisplay(button: button, score: score, isTracking: isTracking)
    }

    /// Update menu bar to show live score with color
    func updateScore(_ score: Double) {
        guard let button = statusItem?.button else { return }
        let isTracking = appState?.isTrackingEnabled ?? false
        updateButtonDisplay(button: button, score: score, isTracking: isTracking)
    }

    private func updateButtonDisplay(button: NSStatusBarButton, score: Double, isTracking: Bool) {
        // Create attributed string with score and icon
        let scoreColor = colorForScore(score)
        let iconName = isTracking ? "chart.bar.fill" : "chart.bar"

        // Create the image
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Kafeel")?.withSymbolConfiguration(config)

        // If tracking, show score + icon with color
        if isTracking && score > 0 {
            let scoreString = String(format: "%.0f", score)

            // Create attributed string for score
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: scoreColor,
                .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
            ]
            let attributedScore = NSAttributedString(string: scoreString + " ", attributes: attributes)

            button.attributedTitle = attributedScore
            button.image = image
            button.imagePosition = .imageRight
        } else {
            // Just show icon when not tracking or no score
            button.title = ""
            button.image = image
            button.imagePosition = .imageOnly
        }
    }

    private func colorForScore(_ score: Double) -> NSColor {
        switch score {
        case 75...100:
            return NSColor.systemGreen
        case 50..<75:
            return NSColor.systemOrange
        default:
            return NSColor.systemRed
        }
    }

    func cleanup() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        popover = nil
        statusItem = nil
    }
}
