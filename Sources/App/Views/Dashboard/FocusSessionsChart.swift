import SwiftUI
import Charts
import KafeelCore

struct FocusSessionsChart: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]

    @State private var selectedSession: FocusSession?
    @State private var isAnimated = false

    private let focusThresholdMinutes = 25

    private var focusSessions: [FocusSession] {
        var sessions: [FocusSession] = []
        var currentSession: FocusSession?

        let sortedActivities = activities.sorted { $0.startTime < $1.startTime }

        for activity in sortedActivities {
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let durationMinutes = activity.durationSeconds / 60

            // Only productive apps count as focus sessions
            guard category == .productive else {
                // End current session if exists
                if let session = currentSession {
                    sessions.append(session)
                    currentSession = nil
                }
                continue
            }

            if let session = currentSession {
                // Check if this activity is within 5 minutes of the last activity
                let timeSinceLastActivity = activity.startTime.timeIntervalSince(session.endTime)
                if timeSinceLastActivity <= 300 { // 5 minutes
                    // Extend current session
                    currentSession = FocusSession(
                        id: session.id,
                        startTime: session.startTime,
                        endTime: activity.endTime ?? Date(),
                        durationMinutes: session.durationMinutes + durationMinutes,
                        apps: session.apps + [activity.appName]
                    )
                } else {
                    // Start new session
                    sessions.append(session)
                    currentSession = FocusSession(
                        id: UUID(),
                        startTime: activity.startTime,
                        endTime: activity.endTime ?? Date(),
                        durationMinutes: durationMinutes,
                        apps: [activity.appName]
                    )
                }
            } else {
                // Start new session
                currentSession = FocusSession(
                    id: UUID(),
                    startTime: activity.startTime,
                    endTime: activity.endTime ?? Date(),
                    durationMinutes: durationMinutes,
                    apps: [activity.appName]
                )
            }
        }

        // Add the last session if exists
        if let session = currentSession {
            sessions.append(session)
        }

        // Filter sessions that are at least focusThresholdMinutes long
        return sessions.filter { $0.durationMinutes >= focusThresholdMinutes }
    }

    private var totalDeepWorkTime: Int {
        focusSessions.map(\.durationMinutes).reduce(0, +)
    }

    private var formattedDeepWorkTime: String {
        let hours = totalDeepWorkTime / 60
        let minutes = totalDeepWorkTime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus Sessions")
                        .font(.title3.weight(.semibold))

                    Text("\(focusSessions.count) sessions (\(focusThresholdMinutes)+ min) • \(formattedDeepWorkTime) deep work")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Deep work badge
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                    Text(formattedDeepWorkTime)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                )
            }

            if focusSessions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 16) {
                    // Timeline
                    ScrollView(.horizontal, showsIndicators: false) {
                        timelineView
                            .padding(.vertical, 8)
                    }

                    // Stats
                    statsView
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                isAnimated = true
            }
        }
        .onChange(of: activities) { _, _ in
            isAnimated = false
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                isAnimated = true
            }
        }
    }

    private var timelineView: some View {
        HStack(spacing: 8) {
            ForEach(Array(focusSessions.enumerated()), id: \.element.id) { index, session in
                sessionBlock(for: session, index: index)
            }
        }
        .frame(height: 80)
    }

    private func sessionBlock(for session: FocusSession, index: Int) -> some View {
        let isSelected = selectedSession?.id == session.id
        let width = CGFloat(min(session.durationMinutes, 120)) * 2 // Scale for display

        return VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(sessionGradient)
                .frame(width: width, height: 50)
                .overlay(
                    VStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)

                        Text("\(session.durationMinutes)m")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                )
                .scaleEffect(isSelected ? 1.05 : (isAnimated ? 1.0 : 0.8))
                .shadow(
                    color: isSelected ? Color.purple.opacity(0.4) : Color.clear,
                    radius: isSelected ? 8 : 0
                )

            Text(formatTime(session.startTime))
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedSession = selectedSession?.id == session.id ? nil : session
            }
        }
    }

    private var sessionGradient: LinearGradient {
        LinearGradient(
            colors: [Color.purple, Color.blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var statsView: some View {
        HStack(spacing: 16) {
            statCard(
                icon: "chart.bar.fill",
                title: "Sessions",
                value: "\(focusSessions.count)",
                color: .blue
            )

            statCard(
                icon: "clock.fill",
                title: "Avg Duration",
                value: "\(focusSessions.isEmpty ? 0 : totalDeepWorkTime / focusSessions.count)m",
                color: .purple
            )

            statCard(
                icon: "star.fill",
                title: "Longest",
                value: "\(focusSessions.map(\.durationMinutes).max() ?? 0)m",
                color: .orange
            )
        }
    }

    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(10)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No focus sessions yet")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Work on productive apps for \(focusThresholdMinutes)+ minutes")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct FocusSession: Identifiable, Equatable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let durationMinutes: Int
    let apps: [String]

    var uniqueApps: [String] {
        Array(Set(apps)).sorted()
    }

    static func == (lhs: FocusSession, rhs: FocusSession) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    let now = Date()
    let activities = [
        ActivityLog(appBundleIdentifier: "com.apple.Xcode", appName: "Xcode", startTime: now.addingTimeInterval(-5400)),
        ActivityLog(appBundleIdentifier: "com.apple.Xcode", appName: "Xcode", startTime: now.addingTimeInterval(-3600)),
        ActivityLog(appBundleIdentifier: "com.apple.Terminal", appName: "Terminal", startTime: now.addingTimeInterval(-1800)),
    ]

    for activity in activities {
        activity.finalize()
    }

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.apple.Terminal": CategoryType.productive,
    ]

    return VStack {
        FocusSessionsChart(activities: activities, categories: categories)
        FocusSessionsChart(activities: [], categories: [:])
    }
    .padding()
    .frame(width: 700)
}
