import SwiftUI
import Charts
import SwiftData
import KafeelCore

struct AppUsageChart: View {
    let stats: [AppUsageStat]
    let categories: [String: CategoryType]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Usage")
                        .font(.title3.weight(.semibold))

                    Text("Top 10 most used applications")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Legend
                HStack(spacing: 12) {
                    legendItem(color: .green, label: "Productive")
                    legendItem(color: .gray, label: "Neutral")
                    legendItem(color: .red, label: "Distracting")
                }
                .font(.caption)
            }

            if stats.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(stats.prefix(10)) { stat in
                        BarMark(
                            x: .value("Duration", Double(stat.totalSeconds) / 60.0),
                            y: .value("App", stat.appName)
                        )
                        .foregroundStyle(categoryGradient(for: stat.bundleIdentifier))
                        .cornerRadius(6)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let minutes = value.as(Double.self) {
                                Text("\(Int(minutes))m")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.secondary.opacity(0.2))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let appName = value.as(String.self) {
                                Text(appName)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(min(stats.count, 10)) * 44 + 20)
            }
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No activity data yet")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Start using apps to see your usage patterns")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    private func categoryColor(for bundleId: String) -> Color {
        let category = categories[bundleId] ?? .neutral
        return category.color
    }

    private func categoryGradient(for bundleId: String) -> LinearGradient {
        let category = categories[bundleId] ?? .neutral
        let color = category.color

        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

#Preview {
    let stats = [
        AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200),
        AppUsageStat(bundleIdentifier: "com.google.Chrome", appName: "Chrome", totalSeconds: 3600),
        AppUsageStat(bundleIdentifier: "com.apple.Safari", appName: "Safari", totalSeconds: 1800),
        AppUsageStat(bundleIdentifier: "com.apple.Music", appName: "Music", totalSeconds: 900),
    ]

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.google.Chrome": CategoryType.neutral,
        "com.apple.Safari": CategoryType.neutral,
        "com.apple.Music": CategoryType.distracting,
    ]

    return VStack {
        AppUsageChart(stats: stats, categories: categories)
        AppUsageChart(stats: [], categories: [:])
    }
    .padding()
    .frame(width: 600)
}
