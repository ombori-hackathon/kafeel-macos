import SwiftUI
import Charts
import KafeelCore

struct CategoryPieChart: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]

    @State private var selectedCategory: CategoryData?
    @State private var isAnimated = false

    private var categoryData: [CategoryData] {
        var productive = 0
        var neutral = 0
        var distracting = 0

        for activity in activities {
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let duration = activity.durationSeconds

            switch category {
            case .productive:
                productive += duration
            case .neutral:
                neutral += duration
            case .distracting:
                distracting += duration
            }
        }

        let total = productive + neutral + distracting
        guard total > 0 else { return [] }

        return [
            CategoryData(
                id: UUID(),
                category: .productive,
                seconds: productive,
                percentage: Double(productive) / Double(total) * 100
            ),
            CategoryData(
                id: UUID(),
                category: .neutral,
                seconds: neutral,
                percentage: Double(neutral) / Double(total) * 100
            ),
            CategoryData(
                id: UUID(),
                category: .distracting,
                seconds: distracting,
                percentage: Double(distracting) / Double(total) * 100
            ),
        ].filter { $0.seconds > 0 }
    }

    private var totalTime: Int {
        categoryData.map(\.seconds).reduce(0, +)
    }

    private var formattedTotalTime: String {
        let hours = totalTime / 3600
        let minutes = (totalTime % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerView

            if categoryData.isEmpty {
                emptyState
            } else {
                chartContent
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
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
                isAnimated = true
            }
        }
        .onChange(of: activities) { _, _ in
            isAnimated = false
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
                isAnimated = true
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Time Distribution")
                .font(.title3.weight(.semibold))

            Text("By category")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var chartContent: some View {
        HStack(spacing: 32) {
            donutChart
            legendView
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var donutChart: some View {
        ZStack {
            Chart(categoryData) { data in
                SectorMark(
                    angle: .value("Time", isAnimated ? data.seconds : 0),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(categoryGradient(for: data.category))
                .cornerRadius(4)
                .opacity(selectedCategory?.id == data.id ? 0.8 : 1.0)
            }
            // .chartAngleSelection(value: $selectedCategory)  // TODO: Requires CategoryData to conform to Plottable
            .frame(width: 180, height: 180)

            centerLabel
        }
    }

    private var centerLabel: some View {
        VStack(spacing: 4) {
            Text(formattedTotalTime)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Total")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(categoryData) { data in
                legendItem(for: data)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.pie")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No time data yet")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func legendItem(for data: CategoryData) -> some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(data.category.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(data.category.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Text(formatDuration(data.seconds))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text("\(Int(data.percentage))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedCategory?.id == data.id ? data.category.color.opacity(0.1) : Color.clear)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = selectedCategory?.id == data.id ? nil : data
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func categoryGradient(for category: CategoryType) -> LinearGradient {
        let color = category.color
        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct CategoryData: Identifiable, Equatable {
    let id: UUID
    let category: CategoryType
    let seconds: Int
    let percentage: Double

    static func == (lhs: CategoryData, rhs: CategoryData) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    let activities = [
        ActivityLog(appBundleIdentifier: "com.apple.Xcode", appName: "Xcode", startTime: Date().addingTimeInterval(-7200)),
        ActivityLog(appBundleIdentifier: "com.google.Chrome", appName: "Chrome", startTime: Date().addingTimeInterval(-3600)),
        ActivityLog(appBundleIdentifier: "com.spotify.client", appName: "Spotify", startTime: Date().addingTimeInterval(-1800)),
    ]

    for activity in activities {
        activity.finalize()
    }

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.google.Chrome": CategoryType.neutral,
        "com.spotify.client": CategoryType.distracting,
    ]

    return VStack {
        CategoryPieChart(activities: activities, categories: categories)
        CategoryPieChart(activities: [], categories: [:])
    }
    .padding()
    .frame(width: 500)
}
