import Foundation

public struct FocusStats {
    public let productiveSeconds: Int
    public let distractingSeconds: Int
    public let neutralSeconds: Int
    public let totalSeconds: Int
    public let switchCount: Int
    public let focusScore: Double

    public init(
        productiveSeconds: Int,
        distractingSeconds: Int,
        neutralSeconds: Int,
        totalSeconds: Int,
        switchCount: Int,
        focusScore: Double
    ) {
        self.productiveSeconds = productiveSeconds
        self.distractingSeconds = distractingSeconds
        self.neutralSeconds = neutralSeconds
        self.totalSeconds = totalSeconds
        self.switchCount = switchCount
        self.focusScore = focusScore
    }
}

public enum FocusScoreCalculator {

    /// Calculate focus score based on activity logs
    /// - Parameters:
    ///   - activities: Array of activity logs to analyze
    ///   - categories: Dictionary mapping bundle identifiers to category types
    ///   - defaultCategory: Default category for apps not in the dictionary
    /// - Returns: Focus score from 0 to 100
    public static func calculate(
        activities: [ActivityLog],
        categories: [String: CategoryType],
        defaultCategory: CategoryType
    ) -> Double {
        let stats = calculateStats(
            activities: activities,
            categories: categories,
            defaultCategory: defaultCategory
        )
        return stats.focusScore
    }

    /// Get label and color for a given focus score
    /// - Parameter score: Focus score from 0 to 100
    /// - Returns: Tuple of label text and color name
    public static func scoreLabel(for score: Double) -> (text: String, color: String) {
        switch score {
        case 80...100:
            return ("Excellent", "green")
        case 60..<80:
            return ("Good", "blue")
        case 40..<60:
            return ("Fair", "yellow")
        case 20..<40:
            return ("Poor", "orange")
        default:
            return ("Very Poor", "red")
        }
    }

    /// Calculate detailed focus statistics
    /// - Parameters:
    ///   - activities: Array of activity logs to analyze
    ///   - categories: Dictionary mapping bundle identifiers to category types
    ///   - defaultCategory: Default category for apps not in the dictionary
    /// - Returns: Detailed focus statistics
    public static func calculateStats(
        activities: [ActivityLog],
        categories: [String: CategoryType],
        defaultCategory: CategoryType = .neutral
    ) -> FocusStats {
        guard !activities.isEmpty else {
            return FocusStats(
                productiveSeconds: 0,
                distractingSeconds: 0,
                neutralSeconds: 0,
                totalSeconds: 0,
                switchCount: 0,
                focusScore: 0
            )
        }

        var productiveSeconds = 0
        var distractingSeconds = 0
        var neutralSeconds = 0
        var switchCount = 0
        var lastBundleId: String?

        for activity in activities {
            let category = categories[activity.appBundleIdentifier] ?? defaultCategory
            let duration = activity.durationSeconds

            switch category {
            case .productive:
                productiveSeconds += duration
            case .distracting:
                distractingSeconds += duration
            case .neutral:
                neutralSeconds += duration
            }

            // Count switches (when app changes)
            if let last = lastBundleId, last != activity.appBundleIdentifier {
                switchCount += 1
            }
            lastBundleId = activity.appBundleIdentifier
        }

        let totalSeconds = productiveSeconds + distractingSeconds + neutralSeconds

        guard totalSeconds > 0 else {
            return FocusStats(
                productiveSeconds: 0,
                distractingSeconds: 0,
                neutralSeconds: 0,
                totalSeconds: 0,
                switchCount: 0,
                focusScore: 0
            )
        }

        // Calculate base score: weighted average of time
        let productiveWeight = 1.0
        let neutralWeight = 0.5
        let distractingWeight = 0.0

        let weightedSum = Double(productiveSeconds) * productiveWeight +
                         Double(neutralSeconds) * neutralWeight +
                         Double(distractingSeconds) * distractingWeight

        let baseScore = (weightedSum / Double(totalSeconds)) * 100.0

        // Calculate context switching penalty
        let totalHours = Double(totalSeconds) / 3600.0
        let switchesPerHour = totalHours > 0 ? Double(switchCount) / totalHours : 0
        let switchPenalty = max(0, switchesPerHour - 10) * 0.5

        // Final score: base score minus penalty, clamped to 0-100
        let finalScore = max(0, min(100, baseScore - switchPenalty))

        return FocusStats(
            productiveSeconds: productiveSeconds,
            distractingSeconds: distractingSeconds,
            neutralSeconds: neutralSeconds,
            totalSeconds: totalSeconds,
            switchCount: switchCount,
            focusScore: finalScore
        )
    }
}
