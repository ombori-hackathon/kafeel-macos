import SwiftUI
import Charts
import KafeelCore
import AppKit

struct AppRankingChart: View {
    let stats: [AppUsageStat]
    let categories: [String: CategoryType]

    @State private var selectedApp: String?
    @State private var isAnimated = false

    private var topApps: [AppRankData] {
        let total = stats.map(\.totalSeconds).reduce(0, +)
        guard total > 0 else { return [] }

        return stats.prefix(10).enumerated().map { index, stat in
            let percentage = Double(stat.totalSeconds) / Double(total) * 100
            let category = categories[stat.bundleIdentifier] ?? .neutral

            return AppRankData(
                id: UUID(),
                rank: index + 1,
                bundleId: stat.bundleIdentifier,
                appName: stat.appName,
                duration: stat.totalSeconds,
                percentage: percentage,
                category: category
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Apps")
                        .font(.title3.weight(.semibold))

                    Text("Most used applications")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Category legend
                HStack(spacing: 12) {
                    legendItem(color: .green, label: "Productive")
                    legendItem(color: .gray, label: "Neutral")
                    legendItem(color: .red, label: "Distracting")
                }
                .font(.caption)
            }

            if topApps.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(topApps) { app in
                        appRankRow(for: app)
                    }
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
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1)) {
                isAnimated = true
            }
        }
        .onChange(of: stats.count) { _, _ in
            isAnimated = false
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1)) {
                isAnimated = true
            }
        }
    }

    private func appRankRow(for app: AppRankData) -> some View {
        let isSelected = selectedApp == app.bundleId

        return HStack(spacing: 12) {
            // Rank badge
            Text("\(app.rank)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(rankGradient(for: app.rank))
                )

            // App icon
            RankingAppIconView(bundleId: app.bundleId)
                .frame(width: 32, height: 32)
                .cornerRadius(6)

            // App info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(formatDuration(app.duration))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text("\(Int(app.percentage))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(app.category.color.opacity(0.1))
                        .frame(width: geometry.size.width, height: 24)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(categoryGradient(for: app.category))
                        .frame(
                            width: isAnimated ? geometry.size.width * (app.percentage / 100) : 0,
                            height: 24
                        )
                        .animation(
                            .spring(response: 1.0, dampingFraction: 0.7)
                                .delay(Double(app.rank) * 0.05),
                            value: isAnimated
                        )

                    HStack {
                        Spacer()
                        Text("\(Int(app.percentage))%")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                    }
                    .frame(width: geometry.size.width, height: 24)
                }
            }
            .frame(width: 100, height: 24)

            // Category indicator
            Circle()
                .fill(app.category.color)
                .frame(width: 8, height: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? app.category.color.opacity(0.05) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isSelected ? app.category.color.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .shadow(
            color: isSelected ? app.category.color.opacity(0.2) : Color.clear,
            radius: isSelected ? 8 : 0
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedApp = selectedApp == app.bundleId ? nil : app.bundleId
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No app data yet")
                .font(.body)
                .foregroundStyle(.secondary)
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

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func rankGradient(for rank: Int) -> LinearGradient {
        switch rank {
        case 1:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2:
            return LinearGradient(colors: [.gray, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3:
            return LinearGradient(colors: [.orange, .brown], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func categoryGradient(for category: CategoryType) -> LinearGradient {
        let color = category.color
        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct AppRankData: Identifiable {
    let id: UUID
    let rank: Int
    let bundleId: String
    let appName: String
    let duration: Int
    let percentage: Double
    let category: CategoryType
}

// Simple app icon view for rankings
private struct RankingAppIconView: View {
    let bundleId: String
    @State private var icon: NSImage?

    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.secondary)
                    .padding(6)
            }
        }
        .onAppear {
            loadIcon()
        }
    }

    private func loadIcon() {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return
        }
        let appIcon = NSWorkspace.shared.icon(forFile: appURL.path)
        icon = appIcon
    }
}

#Preview {
    let stats = [
        AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200),
        AppUsageStat(bundleIdentifier: "com.google.Chrome", appName: "Chrome", totalSeconds: 5400),
        AppUsageStat(bundleIdentifier: "com.apple.Safari", appName: "Safari", totalSeconds: 3600),
        AppUsageStat(bundleIdentifier: "com.apple.Music", appName: "Music", totalSeconds: 2700),
        AppUsageStat(bundleIdentifier: "com.microsoft.VSCode", appName: "VS Code", totalSeconds: 1800),
    ]

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.google.Chrome": CategoryType.neutral,
        "com.apple.Safari": CategoryType.neutral,
        "com.apple.Music": CategoryType.distracting,
        "com.microsoft.VSCode": CategoryType.productive,
    ]

    return VStack {
        AppRankingChart(stats: stats, categories: categories)
        AppRankingChart(stats: [], categories: [:])
    }
    .padding()
    .frame(width: 700)
}
