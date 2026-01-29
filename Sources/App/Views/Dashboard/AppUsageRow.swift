import SwiftUI
import AppKit
import KafeelCore

struct AppUsageRow: View {
    let stat: AppUsageStat
    let category: CategoryType

    @State private var isHovering = false

    private var appIcon: NSImage? {
        NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: stat.bundleIdentifier)?.path ?? "")
    }

    var body: some View {
        Button {
            // Click to show detailed view (can be implemented later)
            print("Clicked on \(stat.appName)")
        } label: {
            HStack(spacing: 14) {
                // App icon with shadow
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                } else {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "app.fill")
                            .font(.title3)
                            .foregroundStyle(category.color)
                    }
                }

                // App name and bundle ID
                VStack(alignment: .leading, spacing: 3) {
                    Text(stat.appName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)

                    Text(stat.bundleIdentifier)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                // Usage percentage bar (visual indicator)
                HStack(spacing: 10) {
                    // Category badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 8, height: 8)

                        Text(category.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(category.color.opacity(0.1))
                    )

                    // Duration
                    Text(stat.formattedDuration)
                        .font(.body.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.primary)
                        .frame(minWidth: 60, alignment: .trailing)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovering ? Color(nsColor: .controlBackgroundColor) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isHovering ? category.color.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isHovering ? 1.01 : 1.0)
            .animation(AppTheme.animationFast, value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        AppUsageRow(
            stat: AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200),
            category: .productive
        )
        AppUsageRow(
            stat: AppUsageStat(bundleIdentifier: "com.google.Chrome", appName: "Chrome", totalSeconds: 3600),
            category: .neutral
        )
        AppUsageRow(
            stat: AppUsageStat(bundleIdentifier: "com.facebook.app", appName: "Facebook", totalSeconds: 1800),
            category: .distracting
        )
    }
    .padding()
    .frame(width: 400)
}
