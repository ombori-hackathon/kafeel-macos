import SwiftUI
import SwiftData
import KafeelCore

struct GitActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GitActivity.date, order: .reverse) private var allCommits: [GitActivity]
    @Query private var settings: [AppSettings]
    @State private var selectedRepository: String = "All Repositories"
    @State private var selectedTimeRange: TimeRange = .week
    @State private var isScanning = false
    @State private var scanError: String?
    @State private var scanProgress: String = ""
    @State private var scanTask: Task<Void, Never>?

    private var appSettings: AppSettings? {
        settings.first
    }

    enum TimeRange: String, CaseIterable {
        case day = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"

        var date: Date {
            let calendar = Calendar.current
            switch self {
            case .day:
                return calendar.startOfDay(for: Date())
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            case .all:
                return Date.distantPast
            }
        }
    }

    private var repositories: [String] {
        let repos = Set(allCommits.map { $0.repositoryName })
        return ["All Repositories"] + repos.sorted()
    }

    private var filteredCommits: [GitActivity] {
        let timeFiltered = allCommits.filter { $0.date >= selectedTimeRange.date }

        if selectedRepository == "All Repositories" {
            return timeFiltered
        } else {
            return timeFiltered.filter { $0.repositoryName == selectedRepository }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with controls
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Git Activity")
                            .font(.largeTitle.bold())

                        Spacer()

                        HStack(spacing: 8) {
                            if isScanning {
                                Button {
                                    cancelScan()
                                } label: {
                                    Label("Cancel", systemImage: "xmark.circle")
                                }
                                .buttonStyle(BorderedButtonStyle())
                            } else {
                                Button {
                                    startScan()
                                } label: {
                                    Label("Scan Now", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }

                    // Show workspace path or warning
                    if let settings = appSettings {
                        if let workspacePath = settings.workspacePath {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.blue)
                                Text("Workspace: \(workspacePath)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("No workspace folder set. Click Scan to search common locations or set workspace in Settings.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let lastScanTime = settings.lastGitScanTime {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(.green)
                                Text("Last scan: \(lastScanTime.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Show error if any
                    if let error = scanError {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                            Spacer()
                            Button("Dismiss") {
                                scanError = nil
                            }
                            .font(.caption)
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }

                    HStack {
                        Picker("Repository", selection: $selectedRepository) {
                            ForEach(repositories, id: \.self) { repo in
                                Text(repo).tag(repo)
                            }
                        }
                        .frame(width: 250)

                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .frame(width: 180)
                    }
                }
                .padding()

                // Stats summary
                GitStatsCard(commits: filteredCommits, timeRange: selectedTimeRange)
                    .padding(.horizontal)

                // Contribution graph
                GitContributionGraph(commits: allCommits)
                    .padding(.horizontal)

                // Commit timeline
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Commits")
                        .font(.title2.bold())
                        .padding(.horizontal)

                    if isScanning {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Scanning repositories...")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            if !scanProgress.isEmpty {
                                Text(scanProgress)
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Text("This may take a few moments")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else if filteredCommits.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "questionmark.folder")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No commits found")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            if appSettings?.workspacePath == nil {
                                Text("Set your workspace folder in Settings, then click 'Scan Now'")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("Click 'Scan Now' to import your Git activity")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredCommits) { commit in
                                CommitRowView(commit: commit)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func startScan() {
        scanTask = Task {
            await scanRepositories()
        }
    }

    private func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        scanProgress = ""
        print("GitActivityView: Scan cancelled by user")
    }

    private func scanRepositories() async {
        isScanning = true
        scanError = nil
        scanProgress = ""
        defer {
            isScanning = false
            scanProgress = ""
        }

        print("GitActivityView: Starting repository scan")

        let gitService = GitService.shared
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

        // Determine search paths
        var searchPaths: [String] = []

        if let workspacePath = appSettings?.workspacePath, !workspacePath.isEmpty {
            // Use workspace path from settings
            print("GitActivityView: Using workspace path from settings: \(workspacePath)")
            if FileManager.default.fileExists(atPath: workspacePath) {
                searchPaths = [workspacePath]
            } else {
                scanError = "Workspace folder does not exist: \(workspacePath)"
                print("GitActivityView: \(scanError!)")
                return
            }
        } else {
            // Scan common development directories
            print("GitActivityView: No workspace path set, scanning common locations")
            let commonPaths = [
                (homeDirectory as NSString).appendingPathComponent("workspace"),
                (homeDirectory as NSString).appendingPathComponent("Developer"),
                (homeDirectory as NSString).appendingPathComponent("Documents"),
                (homeDirectory as NSString).appendingPathComponent("Projects"),
            ]

            searchPaths = commonPaths.filter { path in
                let exists = FileManager.default.fileExists(atPath: path)
                print("GitActivityView: Checking path \(path): \(exists ? "exists" : "not found")")
                return exists
            }

            if searchPaths.isEmpty {
                scanError = "No development folders found. Set a workspace path in Settings."
                print("GitActivityView: \(scanError!)")
                return
            }
        }

        // Check for cancellation
        guard !Task.isCancelled else {
            print("GitActivityView: Scan cancelled before scanning")
            return
        }

        scanProgress = "Searching for repositories..."
        print("GitActivityView: Scanning \(searchPaths.count) paths")
        let repositories = gitService.scanRepositories(in: searchPaths, maxDepth: 3)

        // Check for cancellation
        guard !Task.isCancelled else {
            print("GitActivityView: Scan cancelled after repository search")
            return
        }

        if repositories.isEmpty {
            scanError = "No Git repositories found in the specified locations."
            print("GitActivityView: \(scanError!)")
            return
        }

        print("GitActivityView: Found \(repositories.count) repositories, fetching commits")

        // Fetch commits from last 30 days (optimized)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        var totalCommitsFound = 0

        // Get current user name to filter commits
        let currentUser = gitService.getCurrentUserName()
        if let user = currentUser {
            print("GitActivityView: Filtering commits by author: \(user)")
        }

        for (index, repo) in repositories.enumerated() {
            // Check for cancellation
            guard !Task.isCancelled else {
                print("GitActivityView: Scan cancelled during commit fetch")
                return
            }

            let repoName = (repo as NSString).lastPathComponent
            scanProgress = "Scanning \(repoName) (\(index + 1)/\(repositories.count))..."

            let commits = gitService.fetchCommits(from: repo, since: thirtyDaysAgo, limit: 100, author: currentUser)
            totalCommitsFound += commits.count

            // Insert commits into database
            for commit in commits {
                // Check if commit already exists
                let commitHashToFind = commit.commitHash
                let allActivities = try? modelContext.fetch(FetchDescriptor<GitActivity>())
                let existing = allActivities?.first { $0.commitHash == commitHashToFind }

                if let existing = existing {
                    // Update existing
                    existing.additions = commit.additions
                    existing.deletions = commit.deletions
                    existing.filesChanged = commit.filesChanged
                } else {
                    // Insert new
                    modelContext.insert(commit)
                }
            }
        }

        try? modelContext.save()

        // Update last scan time
        if let settings = appSettings {
            settings.lastGitScanTime = Date()
        }

        print("GitActivityView: Scan complete. Found \(totalCommitsFound) total commits from \(repositories.count) repositories")

        if totalCommitsFound == 0 {
            scanError = "No commits found in the last 30 days. Make sure you have Git repositories with recent activity."
        }
    }
}

#Preview {
    GitActivityView()
        .modelContainer(for: GitActivity.self, inMemory: true)
}
