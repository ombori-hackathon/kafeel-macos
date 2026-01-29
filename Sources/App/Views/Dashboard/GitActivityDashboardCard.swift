import SwiftUI
import KafeelCore

struct GitActivityDashboardCard: View {
    let commits: [GitActivity]

    private var stats: GitRepoStats {
        GitService.shared.getAggregatedStats(from: commits)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.title2)
                    .foregroundStyle(.orange)

                Text("Git Activity")
                    .font(.headline)

                Spacer()

                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                GitStatItem(
                    value: "\(stats.totalCommits)",
                    label: "Commits",
                    color: .orange
                )

                Divider()
                    .frame(height: 40)

                GitStatItem(
                    value: formatNumber(stats.totalAdditions),
                    label: "Lines Added",
                    color: .green
                )

                Divider()
                    .frame(height: 40)

                GitStatItem(
                    value: formatNumber(stats.totalDeletions),
                    label: "Lines Removed",
                    color: .red
                )

                Divider()
                    .frame(height: 40)

                GitStatItem(
                    value: "\(stats.filesChanged)",
                    label: "Files Changed",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fk", Double(num) / 1000.0)
        }
        return "\(num)"
    }
}

struct GitStatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GitActivityDashboardCard(commits: [])
        .padding()
        .frame(width: 600)
}
