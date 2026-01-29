import SwiftUI
import Charts
import KafeelCore

struct DailyHeatmap: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]

    @State private var selectedHour: HourData?
    @State private var hoveredHour: Int?
    @State private var isAnimated = false

    private var hourlyData: [HourData] {
        let calendar = Calendar.current
        var hourlyActivity: [Int: (count: Int, apps: Set<String>, duration: Int)] = [:]

        for activity in activities {
            let hour = calendar.component(.hour, from: activity.startTime)
            var current = hourlyActivity[hour] ?? (0, [], 0)
            current.count += 1
            current.apps.insert(activity.appName)
            current.duration += activity.durationSeconds
            hourlyActivity[hour] = current
        }

        let maxDuration = hourlyActivity.values.map(\.duration).max() ?? 1

        return (0...23).map { hour in
            let data = hourlyActivity[hour] ?? (0, [], 0)
            let intensity = Double(data.duration) / Double(maxDuration)

            return HourData(
                id: UUID(),
                hour: hour,
                activityCount: data.count,
                apps: Array(data.apps).sorted(),
                duration: data.duration,
                intensity: intensity
            )
        }
    }

    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Activity Heatmap")
                        .font(.title3.weight(.semibold))

                    Text("Hour-by-hour activity levels")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Legend
                HStack(spacing: 6) {
                    Text("Low")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.blue.opacity(Double(index + 1) * 0.2))
                                .frame(width: 12, height: 12)
                        }
                    }

                    Text("High")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if hourlyData.allSatisfy({ $0.activityCount == 0 }) {
                emptyState
            } else {
                // Heatmap grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 12),
                    spacing: 4
                ) {
                    ForEach(hourlyData) { data in
                        heatmapCell(for: data)
                    }
                }
                .frame(height: 140)

                // Selected hour details
                if let selected = selectedHour {
                    selectedHourView(selected)
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

    private func heatmapCell(for data: HourData) -> some View {
        let isCurrentHour = data.hour == currentHour
        let isHovered = hoveredHour == data.hour
        let isSelected = selectedHour?.hour == data.hour

        return VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 4)
                .fill(cellColor(for: data))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(
                            isCurrentHour ? Color.blue : Color.clear,
                            lineWidth: isCurrentHour ? 2 : 0
                        )
                )
                .frame(height: 50)
                .scaleEffect(isHovered || isSelected ? 1.05 : (isAnimated ? 1.0 : 0.8))
                .shadow(
                    color: isSelected ? Color.blue.opacity(0.3) : Color.clear,
                    radius: isSelected ? 8 : 0
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedHour = selectedHour?.hour == data.hour ? nil : data
                    }
                }
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.15)) {
                        hoveredHour = hovering ? data.hour : nil
                    }
                }

            Text("\(data.hour):00")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(isCurrentHour ? .blue : .secondary)
        }
    }

    private func cellColor(for data: HourData) -> Color {
        if data.activityCount == 0 {
            return Color.secondary.opacity(0.1)
        }

        let opacity = 0.2 + (data.intensity * 0.8)
        return Color.blue.opacity(opacity)
    }

    private func selectedHourView(_ data: HourData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(data.hour):00 - \(data.hour + 1):00")
                    .font(.body.weight(.semibold))

                Spacer()

                Text(formatDuration(data.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(6)
            }

            if !data.apps.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Apps Used")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 6) {
                        ForEach(data.apps.prefix(10), id: \.self) { app in
                            Text(app)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(12)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No activity today")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
}

struct HourData: Identifiable, Equatable {
    let id: UUID
    let hour: Int
    let activityCount: Int
    let apps: [String]
    let duration: Int
    let intensity: Double

    static func == (lhs: HourData, rhs: HourData) -> Bool {
        lhs.id == rhs.id
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let width = proposal.width ?? 300

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return (CGSize(width: width, height: currentY + lineHeight), positions)
    }
}

#Preview {
    let activities = [
        ActivityLog(appBundleIdentifier: "com.apple.Xcode", appName: "Xcode", startTime: Date().addingTimeInterval(-7200)),
        ActivityLog(appBundleIdentifier: "com.google.Chrome", appName: "Chrome", startTime: Date().addingTimeInterval(-3600)),
    ]

    for activity in activities {
        activity.finalize()
    }

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.google.Chrome": CategoryType.neutral,
    ]

    return VStack {
        DailyHeatmap(activities: activities, categories: categories)
        DailyHeatmap(activities: [], categories: [:])
    }
    .padding()
    .frame(width: 700)
}
