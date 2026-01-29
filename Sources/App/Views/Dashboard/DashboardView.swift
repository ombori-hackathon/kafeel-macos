import SwiftUI
import SwiftData
import KafeelCore

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCard: StatCardType?
    @State private var showAchievements = false

    // Flow Score data
    @Query private var streaks: [Streak]
    @Query private var userProfiles: [UserProfile]
    @Query private var achievements: [Achievement]
    @Query private var personalRecords: [PersonalRecord]

    private var streak: Streak? { streaks.first }
    private var userProfile: UserProfile? { userProfiles.first }
    private var unlockedAchievements: [Achievement] { achievements.filter { $0.isUnlocked } }

    var body: some View {
        @Bindable var state = appState

        ScrollView {
            VStack(spacing: 24) {
                // Header with Time Filter
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Text("Track your productivity and focus")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    TimeFilterPicker(selectedFilter: $state.selectedTimeFilter)
                        .frame(width: 200)
                }

                // Row 1: Focus Score Donut + Compact Stats
                HStack(spacing: 16) {
                    FocusScoreDonut(score: appState.focusScore)
                        .frame(width: 180)

                    CompactStatsView(
                        stats: appState.appUsageStats,
                        activities: appState.todayActivities,
                        categories: fetchCategories()
                    )
                }

                // Row 1.5: Flow Score - Streak, Level, Personal Best
                HStack(spacing: 16) {
                    if let streak = streak {
                        StreakCard(streak: streak)
                    }

                    if let profile = userProfile {
                        LevelProgressBar(userProfile: profile)
                    }

                    if let streak = streak {
                        PersonalBestCard(
                            todayScore: appState.focusScore,
                            records: personalRecords,
                            streak: streak
                        )
                    }
                }

                // Row 1.75: Achievements Button
                if !unlockedAchievements.isEmpty {
                    Button {
                        showAchievements = true
                    } label: {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                            Text("\(unlockedAchievements.count) Achievement\(unlockedAchievements.count == 1 ? "" : "s") Unlocked")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Row 2: Git Activity
                GitActivityDashboardCard(commits: appState.recentGitActivity)

                // Row 3: Weekly Hours + Activity Timeline
                HStack(spacing: 16) {
                    WeeklyHoursChart(activities: appState.todayActivities)

                    HorizontalActivityTimeline(
                        activities: appState.todayActivities,
                        categories: fetchCategories()
                    )
                }

                // Row 4: App Usage Donut + Weekly Focus Circles
                HStack(spacing: 16) {
                    CategoryPieChart(
                        activities: appState.todayActivities,
                        categories: fetchCategories()
                    )

                    WeeklyFocusCircles(
                        activities: appState.todayActivities,
                        categories: fetchCategories()
                    )
                }

                // Row 5: Hourly Activity + Browsing Activity
                HStack(spacing: 16) {
                    HourlyActivityChart(activities: appState.todayActivities)

                    BrowsingActivityCard()
                }

                // Analytics Section Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detailed Analytics")
                        .font(.title2.weight(.bold))

                    Text("In-depth insights and visualizations")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                // Full Stats Cards (clickable)
                StatsCardsView(
                    stats: appState.appUsageStats,
                    activities: appState.todayActivities,
                    categories: fetchCategories(),
                    selectedCard: $selectedCard
                )
                .transition(.opacity)

                // View-specific content based on time filter
                Group {
                    switch appState.selectedTimeFilter {
                    case .day:
                        TimelineView(
                            activities: appState.todayActivities,
                            categories: fetchCategories()
                        )
                        .transition(.opacity.combined(with: .move(edge: .trailing)))

                    case .week:
                        WeeklyHeatmapView(
                            activities: appState.todayActivities,
                            categories: fetchCategories()
                        )
                        .transition(.opacity.combined(with: .move(edge: .trailing)))

                    case .year:
                        AppUsageChart(
                            stats: appState.appUsageStats,
                            categories: fetchCategories()
                        )
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }

                // Insights Section
                InsightsView(
                    stats: appState.appUsageStats,
                    activities: appState.todayActivities,
                    categories: fetchCategories(),
                    timeFilter: appState.selectedTimeFilter
                )
                .transition(.opacity)

                // Charts Grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ],
                    spacing: 20
                ) {
                    // Productivity Trend
                    ProductivityTrendChart(
                        activities: appState.todayActivities,
                        categories: fetchCategories(),
                        timeFilter: appState.selectedTimeFilter
                    )
                    .transition(.opacity)

                    // Screen Time Comparison
                    ScreenTimeComparison(
                        activities: appState.todayActivities,
                        timeFilter: appState.selectedTimeFilter
                    )
                    .transition(.opacity)

                    // App Ranking
                    AppRankingChart(
                        stats: appState.appUsageStats,
                        categories: fetchCategories()
                    )
                    .transition(.opacity)
                }

                // Full-width charts
                VStack(spacing: 20) {
                    // Daily Heatmap (Day view only)
                    if appState.selectedTimeFilter == .day {
                        DailyHeatmap(
                            activities: appState.todayActivities,
                            categories: fetchCategories()
                        )
                        .transition(.opacity)
                    }

                    // Focus Sessions
                    FocusSessionsChart(
                        activities: appState.todayActivities,
                        categories: fetchCategories()
                    )
                    .transition(.opacity)
                }

                // App Usage List
                VStack(alignment: .leading, spacing: 16) {
                    Text("Apps by Usage Time")
                        .font(.title3.weight(.semibold))

                    if appState.appUsageStats.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 8) {
                            ForEach(appState.appUsageStats) { stat in
                                AppUsageRow(
                                    stat: stat,
                                    category: fetchCategories()[stat.bundleIdentifier] ?? .neutral
                                )
                                .transition(.opacity)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                    }
                }
            }
            .padding(32)
        }
        .sheet(item: $selectedCard) { cardType in
            DetailedAnalysisView(
                cardType: cardType,
                stats: appState.appUsageStats,
                activities: appState.todayActivities,
                categories: fetchCategories(),
                timeFilter: appState.selectedTimeFilter
            )
        }
        .sheet(isPresented: $showAchievements) {
            AchievementGalleryView(achievements: achievements)
        }
        .task {
            await appState.refreshData()
        }
        .onChange(of: appState.selectedTimeFilter) { _, _ in
            Task {
                await appState.refreshData()
            }
        }
        .onChange(of: appState.selectedDate) { _, _ in
            Task {
                await appState.refreshData()
            }
        }
        .overlay {
            if appState.isLoading {
                ProgressView("Loading...")
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThickMaterial)
                    )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Text("No activity tracked yet")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                Text("Activity will appear here as you use apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func fetchCategories() -> [String: CategoryType] {
        let descriptor = FetchDescriptor<AppCategory>()
        let categories = (try? modelContext.fetch(descriptor)) ?? []
        return Dictionary(uniqueKeysWithValues: categories.map { ($0.bundleIdentifier, $0.category) })
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ActivityLog.self, AppCategory.self, AppSettings.self, GitActivity.self,
        DailyScore.self, Streak.self, Achievement.self, PersonalRecord.self, UserProfile.self, MeetingSession.self,
        configurations: config
    )

    let appState = AppState(modelContext: container.mainContext)

    DashboardView()
        .environment(appState)
        .modelContainer(container)
        .frame(width: 900, height: 1200)
}
