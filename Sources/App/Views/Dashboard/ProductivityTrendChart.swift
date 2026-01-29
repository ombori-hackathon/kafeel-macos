import SwiftUI
import Charts
import KafeelCore

struct ProductivityTrendChart: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    let timeFilter: TimeFilter

    @State private var selectedDataPoint: ProductivityDataPoint?
    @State private var isAnimated = false

    private var dataPoints: [ProductivityDataPoint] {
        switch timeFilter {
        case .day:
            return hourlyProductivityData()
        case .week:
            return dailyProductivityData()
        case .year:
            return monthlyProductivityData()
        }
    }

    private var averageScore: Double {
        guard !dataPoints.isEmpty else { return 0 }
        return dataPoints.map(\.score).reduce(0, +) / Double(dataPoints.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerView

            if dataPoints.isEmpty {
                emptyState
            } else {
                chartView
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
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.1)) {
                isAnimated = true
            }
        }
        .onChange(of: activities) { _, _ in
            isAnimated = false
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.1)) {
                isAnimated = true
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Productivity Trend")
                    .font(.title3.weight(.semibold))

                Text("Score over time (Avg: \(Int(averageScore)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(scoreColor(averageScore))
                    .frame(width: 8, height: 8)
                Text(scoreLabel(averageScore))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(scoreColor(averageScore))
            }
        }
    }

    private var chartView: some View {
        Chart {
            ForEach(dataPoints) { point in
                AreaMark(
                    x: .value("Time", point.label),
                    y: .value("Score", isAnimated ? point.score : 0)
                )
                .foregroundStyle(areaGradient)
                .interpolationMethod(.catmullRom)
            }

            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Time", point.label),
                    y: .value("Score", isAnimated ? point.score : 0)
                )
                .foregroundStyle(scoreColor(averageScore))
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }

            ForEach(dataPoints) { point in
                PointMark(
                    x: .value("Time", point.label),
                    y: .value("Score", isAnimated ? point.score : 0)
                )
                .foregroundStyle(scoreColor(point.score))
                .symbolSize(selectedDataPoint?.id == point.id ? 100 : 60)
            }

            averageRuleMark
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.1))
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisValueLabel {
                    if let score = value.as(Double.self) {
                        Text("\(Int(score))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.1))
            }
        }
        .chartYScale(domain: 0...100)
        .frame(height: 220)
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [
                scoreColor(averageScore).opacity(0.3),
                scoreColor(averageScore).opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var averageRuleMark: some ChartContent {
        RuleMark(y: .value("Average", isAnimated ? averageScore : 0))
            .foregroundStyle(.secondary.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .annotation(position: .trailing, alignment: .leading) {
                Text("Avg")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .cornerRadius(4)
            }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No trend data yet")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func hourlyProductivityData() -> [ProductivityDataPoint] {
        let calendar = Calendar.current
        var hourlyScores: [Int: (productive: Int, neutral: Int, distracting: Int, total: Int)] = [:]

        for activity in activities {
            let hour = calendar.component(.hour, from: activity.startTime)
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let duration = activity.durationSeconds

            var current = hourlyScores[hour] ?? (0, 0, 0, 0)
            switch category {
            case .productive:
                current.productive += duration
            case .neutral:
                current.neutral += duration
            case .distracting:
                current.distracting += duration
            }
            current.total += duration
            hourlyScores[hour] = current
        }

        return (0...23).compactMap { hour in
            guard let data = hourlyScores[hour], data.total > 0 else { return nil }
            let score = (Double(data.productive) * 1.0 + Double(data.neutral) * 0.5) / Double(data.total) * 100
            return ProductivityDataPoint(
                id: UUID(),
                label: "\(hour):00",
                score: score,
                time: Date()
            )
        }
    }

    private func dailyProductivityData() -> [ProductivityDataPoint] {
        let calendar = Calendar.current
        var dailyScores: [String: (productive: Int, neutral: Int, distracting: Int, total: Int)] = [:]

        for activity in activities {
            let dayKey = calendar.startOfDay(for: activity.startTime).formatted(.dateTime.month().day())
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let duration = activity.durationSeconds

            var current = dailyScores[dayKey] ?? (0, 0, 0, 0)
            switch category {
            case .productive:
                current.productive += duration
            case .neutral:
                current.neutral += duration
            case .distracting:
                current.distracting += duration
            }
            current.total += duration
            dailyScores[dayKey] = current
        }

        let points = dailyScores.map { day, data -> ProductivityDataPoint in
            let weightedTime = Double(data.productive) * 1.0 + Double(data.neutral) * 0.5
            let score = data.total > 0 ? (weightedTime / Double(data.total) * 100) : 0
            return ProductivityDataPoint(
                id: UUID(),
                label: day,
                score: score,
                time: Date()
            )
        }
        return points.sorted { $0.label < $1.label }
    }

    private func monthlyProductivityData() -> [ProductivityDataPoint] {
        var monthlyScores: [String: (productive: Int, neutral: Int, distracting: Int, total: Int)] = [:]

        for activity in activities {
            let monthKey = activity.startTime.formatted(.dateTime.month())
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let duration = activity.durationSeconds

            var current = monthlyScores[monthKey] ?? (0, 0, 0, 0)
            switch category {
            case .productive:
                current.productive += duration
            case .neutral:
                current.neutral += duration
            case .distracting:
                current.distracting += duration
            }
            current.total += duration
            monthlyScores[monthKey] = current
        }

        let points = monthlyScores.map { month, data -> ProductivityDataPoint in
            let weightedTime = Double(data.productive) * 1.0 + Double(data.neutral) * 0.5
            let score = data.total > 0 ? (weightedTime / Double(data.total) * 100) : 0
            return ProductivityDataPoint(
                id: UUID(),
                label: month,
                score: score,
                time: Date()
            )
        }
        return points.sorted { $0.label < $1.label }
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }

    private func scoreLabel(_ score: Double) -> String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        case 20..<40: return "Poor"
        default: return "Low"
        }
    }
}

struct ProductivityDataPoint: Identifiable {
    let id: UUID
    let label: String
    let score: Double
    let time: Date
}

#Preview {
    let activities = [
        ActivityLog(appBundleIdentifier: "com.apple.Xcode", appName: "Xcode", startTime: Date().addingTimeInterval(-3600)),
        ActivityLog(appBundleIdentifier: "com.google.Chrome", appName: "Chrome", startTime: Date().addingTimeInterval(-1800)),
    ]

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.google.Chrome": CategoryType.neutral,
    ]

    return VStack {
        ProductivityTrendChart(activities: activities, categories: categories, timeFilter: .day)
        ProductivityTrendChart(activities: [], categories: [:], timeFilter: .day)
    }
    .padding()
    .frame(width: 700)
}
