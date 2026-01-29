import SwiftUI
import SwiftData
import KafeelCore

struct MenuBarPopoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @Query private var streaks: [Streak]
    @Query private var userProfiles: [UserProfile]
    var appState: AppState

    private var appSettings: AppSettings? {
        settings.first
    }

    private var streak: Streak? {
        streaks.first
    }

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            Divider()

            // Focus Score
            focusScoreSection
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            Divider()

            // Stats
            statsSection
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            Divider()

            // Streak & Level
            streakLevelSection
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            Divider()

            // Top Apps
            topAppsSection
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            Spacer()

            Divider()

            // Actions
            actionsSection
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
        .frame(width: 350, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var headerView: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Kafeel")
                    .font(.title3.weight(.bold))
                Text("Activity Tracker")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Tracking status indicator
            Circle()
                .fill(appState.isTrackingEnabled ? Color.green : Color.red)
                .frame(width: 10, height: 10)
        }
    }

    private var focusScoreSection: some View {
        VStack(spacing: 8) {
            Text("Focus Score")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(String(format: "%.0f", appState.focusScore))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(focusScoreColor)

            Text(focusScoreDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var focusScoreColor: Color {
        switch appState.focusScore {
        case 75...100: return .green
        case 50..<75: return .orange
        default: return .red
        }
    }

    private var focusScoreDescription: String {
        switch appState.focusScore {
        case 75...100: return "Excellent Focus"
        case 50..<75: return "Good Focus"
        case 25..<50: return "Moderate Focus"
        default: return "Needs Improvement"
        }
    }

    private var statsSection: some View {
        HStack(spacing: 20) {
            statItem(
                title: "Screen Time",
                value: totalScreenTime,
                icon: "clock.fill",
                color: .blue
            )

            Divider()
                .frame(height: 40)

            statItem(
                title: "Apps Used",
                value: "\(appState.appUsageStats.count)",
                icon: "app.fill",
                color: .purple
            )
        }
    }

    private var totalScreenTime: String {
        let totalSeconds = appState.todayActivities.reduce(0) { $0 + $1.durationSeconds }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private var streakLevelSection: some View {
        HStack(spacing: 16) {
            // Streak
            if let streak = streak {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(streak.isActive ? .orange : .gray)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(streak.currentStreakDays)")
                            .font(.headline.monospacedDigit())
                        Text("day streak")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if streak.streakShields > 0 {
                        Image(systemName: "shield.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("\(streak.streakShields)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Level
            if let profile = userProfile {
                HStack(spacing: 6) {
                    Image(systemName: profile.tier.icon)
                        .foregroundStyle(tierColor(profile.tier))
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Lv \(profile.level)")
                            .font(.headline.monospacedDigit())
                        Text(profile.tier.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func tierColor(_ tier: UserTier) -> Color {
        switch tier {
        case .apprentice: return .green
        case .journeyman: return .blue
        case .expert: return .purple
        case .master: return .orange
        }
    }

    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.weight(.semibold))

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Apps Today")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if appState.appUsageStats.isEmpty {
                Text("No activity yet today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(appState.appUsageStats.prefix(3))) { stat in
                        HStack {
                            Text(stat.appName)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            Text(stat.formattedDuration)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            // Tracking toggle
            if let settings = appSettings {
                Button {
                    if settings.isTrackingEnabled {
                        settings.pauseTracking()
                        appState.stopTracking()
                    } else {
                        settings.resumeTracking()
                        appState.startTracking()
                    }
                } label: {
                    HStack {
                        Image(systemName: settings.isTrackingEnabled ? "pause.fill" : "play.fill")
                        Text(settings.isTrackingEnabled ? "Pause Tracking" : "Resume Tracking")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(settings.isTrackingEnabled ? .orange : .green)
            }

            HStack(spacing: 10) {
                // Open main window
                Button {
                    openMainWindow()
                } label: {
                    HStack {
                        Image(systemName: "app.dashed")
                        Text("Open Kafeel")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                // Quit
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func openMainWindow() {
        // Activate app and bring main window to front
        NSApplication.shared.activate(ignoringOtherApps: true)

        // Find and order front the main window
        if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "MainWindow" }) {
            window.makeKeyAndOrderFront(nil)
        } else if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
