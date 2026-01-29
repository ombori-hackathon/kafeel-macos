import Foundation
import SwiftUI
import SwiftData
import KafeelCore

@MainActor
@Observable
final class AppState {
    var selectedTimeFilter: TimeFilter = .day
    var selectedDate: Date = Date()
    var isLoading: Bool = false
    var todayActivities: [ActivityLog] = []
    var focusScore: Double = 0.0
    var appUsageStats: [AppUsageStat] = []

    // Git Activity
    var recentGitActivity: [GitActivity] = []
    var weeklyFocusScores: [Double] = []

    // Activity Monitor
    var activityMonitor: ActivityMonitor
    var isTrackingEnabled: Bool = true

    // Dependencies
    private var modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        self.activityMonitor = ActivityMonitor()
    }

    func startTracking() {
        activityMonitor.startMonitoring()
        isTrackingEnabled = true
    }

    func stopTracking() {
        activityMonitor.stopMonitoring()
        isTrackingEnabled = false
    }

    // MARK: - Refresh Data

    func refreshData() async {
        isLoading = true
        defer { isLoading = false }

        guard let modelContext = modelContext else {
            // Use mock data if no context available (preview mode)
            loadMockData()
            return
        }

        do {
            // Get date range based on filter
            let (startDate, endDate) = selectedTimeFilter.dateRange(from: selectedDate)

            // Fetch activities in date range
            let descriptor = FetchDescriptor<ActivityLog>(
                predicate: #Predicate<ActivityLog> { activity in
                    activity.startTime >= startDate && activity.startTime < endDate
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )

            todayActivities = try modelContext.fetch(descriptor)

            // Calculate app usage statistics
            calculateAppUsageStats()

            // Calculate focus score
            calculateFocusScore(modelContext: modelContext)
            // Fetch git activity
            fetchGitActivity(modelContext: modelContext)

        } catch {
            print("Error refreshing data: \(error)")
            todayActivities = []
            appUsageStats = []
            focusScore = 0
        }
    }

    private func fetchGitActivity(modelContext: ModelContext) {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<GitActivity>(
            predicate: #Predicate<GitActivity> { activity in
                activity.date >= thirtyDaysAgo
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            recentGitActivity = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching git activity: \(error)")
            recentGitActivity = []
        }
    }

    // MARK: - Private Helpers

    private func calculateAppUsageStats() {
        var usageDict: [String: (name: String, duration: Int)] = [:]

        for activity in todayActivities {
            let key = activity.appBundleIdentifier
            let currentDuration = usageDict[key]?.duration ?? 0
            usageDict[key] = (
                name: activity.appName,
                duration: currentDuration + activity.durationSeconds
            )
        }

        appUsageStats = usageDict.map { bundleId, data in
            AppUsageStat(
                bundleIdentifier: bundleId,
                appName: data.name,
                totalSeconds: data.duration
            )
        }.sorted { $0.totalSeconds > $1.totalSeconds }
    }

    private func calculateFocusScore(modelContext: ModelContext) {
        guard !todayActivities.isEmpty else {
            focusScore = 0
            return
        }

        // Fetch all app categories
        let descriptor = FetchDescriptor<AppCategory>()
        let categories: [AppCategory]
        do {
            categories = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching categories: \(error)")
            focusScore = 0
            return
        }

        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.bundleIdentifier, $0.category) })

        // Calculate weighted score
        var totalWeightedTime: Double = 0
        var totalTime: Double = 0

        for activity in todayActivities {
            let duration = Double(activity.durationSeconds)
            let category = categoryMap[activity.appBundleIdentifier] ?? .neutral
            let weight = category.weight

            totalWeightedTime += duration * weight
            totalTime += duration
        }

        focusScore = totalTime > 0 ? (totalWeightedTime / totalTime) * 100 : 0
    }

    private func loadMockData() {
        // Mock data for previews
        appUsageStats = [
            AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200),
            AppUsageStat(bundleIdentifier: "com.google.Chrome", appName: "Chrome", totalSeconds: 3600),
            AppUsageStat(bundleIdentifier: "com.apple.Safari", appName: "Safari", totalSeconds: 1800),
            AppUsageStat(bundleIdentifier: "com.apple.Music", appName: "Music", totalSeconds: 900),
        ]
        focusScore = 75.0
    }
}

// MARK: - Supporting Types

enum TimeFilter: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case year = "Year"

    var id: String { rawValue }

    func dateRange(from date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current

        switch self {
        case .day:
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)

        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return (start, end)

        case .year:
            let start = calendar.dateInterval(of: .year, for: date)?.start ?? date
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        }
    }
}

struct AppUsageStat: Identifiable {
    let id = UUID()
    let bundleIdentifier: String
    let appName: String
    let totalSeconds: Int

    var formattedDuration: String {
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
}
