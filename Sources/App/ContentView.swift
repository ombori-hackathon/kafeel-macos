import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case calendar = "Calendar"
    case git = "Git"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .calendar: return "calendar"
        case .git: return "chevron.left.forwardslash.chevron.right"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedItem: NavigationItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            // Modern Sidebar
            List(NavigationItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.body.weight(.medium))
                            .foregroundStyle(selectedItem == item ? item.accentColor : .secondary)
                            .frame(width: 24)

                        Text(item.rawValue)
                            .font(.body.weight(selectedItem == item ? .semibold : .regular))
                    }
                    .padding(.vertical, 4)
                }
                .listItemTint(item.accentColor)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 240)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            // App icon - using our custom AppIconView
                            AppIconView(size: 32)
                                .frame(width: 32, height: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("kafeel")
                                    .font(.title3.weight(.bold))
                                Text("Activity Tracker")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Footer with app version
                VStack(spacing: 8) {
                    Divider()

                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.green)

                        Text("Tracking active")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(.ultraThinMaterial)
            }
        } detail: {
            // Detail view with modern transitions
            Group {
                switch selectedItem {
                case .dashboard:
                    DashboardView()
                        .id("dashboard")
                case .calendar:
                    CalendarView()
                        .id("calendar")
                case .git:
                    GitActivityView()
                        .id("git")
                case .settings:
                    SettingsView()
                        .id("settings")
                case .none:
                    emptyDetailView
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    private var emptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sidebar.leading")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select an item")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Navigation Item Extensions

extension NavigationItem {
    var accentColor: Color {
        switch self {
        case .dashboard: return .blue
        case .calendar: return .purple
        case .git: return .orange
        case .settings: return .gray
        }
    }
}

#Preview {
    ContentView()
}
