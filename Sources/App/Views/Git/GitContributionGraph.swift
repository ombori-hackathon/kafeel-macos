import SwiftUI
import KafeelCore

struct GitContributionGraph: View {
    let commits: [GitActivity]
    @State private var hoveredDate: Date?

    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3

    private var contributionData: [Date: Int] {
        let calendar = Calendar.current
        var data: [Date: Int] = [:]

        for commit in commits {
            let day = calendar.startOfDay(for: commit.date)
            data[day, default: 0] += 1
        }

        return data
    }

    private var weeks: [[Date?]] {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -364, to: today) ?? today

        var weeks: [[Date?]] = Array(repeating: Array(repeating: nil, count: 7), count: 53)
        var currentDate = startDate

        var weekIndex = 0
        while currentDate <= today && weekIndex < 53 {
            let weekday = calendar.component(.weekday, from: currentDate)
            let dayIndex = (weekday + 5) % 7 // Convert to Monday = 0

            weeks[weekIndex][dayIndex] = currentDate

            if dayIndex == 6 {
                weekIndex += 1
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return weeks
    }

    private func intensity(for count: Int) -> Color {
        if count == 0 {
            return Color.gray.opacity(0.1)
        } else if count <= 2 {
            return Color.green.opacity(0.3)
        } else if count <= 5 {
            return Color.green.opacity(0.5)
        } else if count <= 10 {
            return Color.green.opacity(0.7)
        } else {
            return Color.green.opacity(0.9)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contribution Graph")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                // Day labels
                HStack(spacing: cellSpacing) {
                    // Empty space for alignment
                    Spacer()
                        .frame(width: 30)

                    ForEach(0..<53, id: \.self) { weekIndex in
                        Spacer()
                            .frame(width: cellSize)
                        if weekIndex < 52 {
                            Spacer()
                                .frame(width: cellSpacing)
                        }
                    }
                }

                // Contribution grid
                HStack(alignment: .top, spacing: 0) {
                    // Weekday labels
                    VStack(alignment: .trailing, spacing: cellSpacing) {
                        ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                            Text(day)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: 30, height: cellSize, alignment: .trailing)
                        }
                    }

                    // Weeks grid
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: cellSpacing) {
                            ForEach(weeks.indices, id: \.self) { weekIndex in
                                VStack(spacing: cellSpacing) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        if let date = weeks[weekIndex][dayIndex] {
                                            ContributionCell(
                                                date: date,
                                                count: contributionData[date] ?? 0,
                                                intensity: intensity(for: contributionData[date] ?? 0),
                                                cellSize: cellSize,
                                                isHovered: hoveredDate == date
                                            )
                                            .onHover { isHovered in
                                                hoveredDate = isHovered ? date : nil
                                            }
                                        } else {
                                            Rectangle()
                                                .fill(.clear)
                                                .frame(width: cellSize, height: cellSize)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.leading, 4)
                    }
                }

                // Legend
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ForEach([0, 2, 5, 10, 15], id: \.self) { count in
                        Rectangle()
                            .fill(intensity(for: count))
                            .frame(width: cellSize, height: cellSize)
                            .cornerRadius(2)
                    }

                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }

            // Tooltip
            if let hoveredDate = hoveredDate {
                HStack {
                    Text("\(contributionData[hoveredDate] ?? 0) commits on \(hoveredDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .cornerRadius(12)
    }
}

struct ContributionCell: View {
    let date: Date
    let count: Int
    let intensity: Color
    let cellSize: CGFloat
    let isHovered: Bool

    var body: some View {
        Rectangle()
            .fill(intensity)
            .frame(width: cellSize, height: cellSize)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isHovered ? .white : .clear, lineWidth: 2)
            )
            .scaleEffect(isHovered ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}

#Preview {
    let calendar = Calendar.current
    let commits = (0..<100).map { index in
        let daysAgo = Int.random(in: 0...365)
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return GitActivity(
            commitHash: "hash\(index)",
            message: "Commit \(index)",
            author: "Author",
            date: date,
            repositoryPath: "/test",
            repositoryName: "test-repo",
            additions: Int.random(in: 10...100),
            deletions: Int.random(in: 0...50),
            filesChanged: Int.random(in: 1...10)
        )
    }

    return GitContributionGraph(commits: commits)
        .padding()
        .frame(width: 800)
}
