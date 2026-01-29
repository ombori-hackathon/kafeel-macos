import SwiftUI
import KafeelCore

struct GitStatsCard: View {
    let commits: [GitActivity]
    let timeRange: GitActivityView.TimeRange

    private var totalCommits: Int {
        commits.count
    }

    private var totalAdditions: Int {
        commits.reduce(0) { $0 + $1.additions }
    }

    private var totalDeletions: Int {
        commits.reduce(0) { $0 + $1.deletions }
    }

    private var mostActiveRepository: String? {
        let repoCounts = Dictionary(grouping: commits) { $0.repositoryName }
            .mapValues { $0.count }
        return repoCounts.max(by: { $0.value < $1.value })?.key
    }

    private var commitStreak: Int {
        guard !commits.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedDates = commits
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()
            .reversed()

        // Remove duplicates
        let uniqueDates = Array(Set(sortedDates)).sorted().reversed()

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for commitDate in uniqueDates {
            if calendar.isDate(commitDate, inSameDayAs: currentDate) {
                streak = max(1, streak)
            } else if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate),
                      calendar.isDate(commitDate, inSameDayAs: previousDay) {
                streak += 1
                currentDate = previousDay
            } else {
                break
            }
        }

        return streak
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.title2.bold())

            HStack(spacing: 20) {
                // Total commits
                StatBox(
                    title: "Commits",
                    value: "\(totalCommits)",
                    icon: "checkmark.circle.fill",
                    color: .blue,
                    subtitle: timeRange.rawValue
                )

                // Lines added
                StatBox(
                    title: "Added",
                    value: "+\(totalAdditions)",
                    icon: "plus.circle.fill",
                    color: .green,
                    subtitle: "lines"
                )

                // Lines deleted
                StatBox(
                    title: "Deleted",
                    value: "-\(totalDeletions)",
                    icon: "minus.circle.fill",
                    color: .red,
                    subtitle: "lines"
                )

                // Commit streak
                StatBox(
                    title: "Streak",
                    value: "\(commitStreak)",
                    icon: "flame.fill",
                    color: .orange,
                    subtitle: commitStreak == 1 ? "day" : "days"
                )

                // Most active repo
                if let mostActive = mostActiveRepository {
                    StatBox(
                        title: "Most Active",
                        value: mostActive,
                        icon: "folder.fill",
                        color: .purple,
                        subtitle: nil
                    )
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .cornerRadius(12)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .cornerRadius(8)
    }
}

#Preview {
    GitStatsCard(
        commits: [
            GitActivity(
                commitHash: "abc123",
                message: "Test commit 1",
                author: "John Doe",
                date: Date(),
                repositoryPath: "/test",
                repositoryName: "kafeel",
                additions: 100,
                deletions: 20,
                filesChanged: 5
            ),
            GitActivity(
                commitHash: "def456",
                message: "Test commit 2",
                author: "Jane Smith",
                date: Date().addingTimeInterval(-86400),
                repositoryPath: "/test",
                repositoryName: "other-repo",
                additions: 50,
                deletions: 10,
                filesChanged: 3
            )
        ],
        timeRange: .week
    )
    .padding()
}
