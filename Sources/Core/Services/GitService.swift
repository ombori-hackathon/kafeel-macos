import Foundation

public struct GitRepoStats {
    public let totalCommits: Int
    public let totalAdditions: Int
    public let totalDeletions: Int
    public let commitStreak: Int
    public let mostActiveDay: Date?
    public let filesChanged: Int

    public init(
        totalCommits: Int,
        totalAdditions: Int,
        totalDeletions: Int,
        commitStreak: Int,
        mostActiveDay: Date? = nil,
        filesChanged: Int = 0
    ) {
        self.totalCommits = totalCommits
        self.totalAdditions = totalAdditions
        self.totalDeletions = totalDeletions
        self.commitStreak = commitStreak
        self.mostActiveDay = mostActiveDay
        self.filesChanged = filesChanged
    }
}

@MainActor
public final class GitService {
    public static let shared = GitService()

    private init() {}

    /// Get the current git user name from global config
    public func getCurrentUserName() -> String? {
        guard let output = runGitCommand(["config", "--global", "user.name"], in: FileManager.default.currentDirectoryPath, timeout: 2.0) else {
            return nil
        }
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public func scanRepositories(in directories: [String], maxDepth: Int = 3) -> [String] {
        var repositories = Set<String>()

        print("GitService: Starting scan of \(directories.count) directories (max depth: \(maxDepth))")

        // Folders to skip during scanning
        let skipFolders = Set([
            "node_modules", ".build", "DerivedData", "Pods", "build",
            "target", "dist", ".svn", "Library", "Applications"
        ])

        let fileManager = FileManager.default

        for directory in directories {
            print("GitService: Scanning directory: \(directory)")

            // Verify directory exists
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: directory, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                print("GitService: Directory does not exist or is not a directory: \(directory)")
                continue
            }

            // Check if directory itself is a git repo
            let gitPath = (directory as NSString).appendingPathComponent(".git")
            if fileManager.fileExists(atPath: gitPath) {
                print("GitService: Found git repo at: \(directory)")
                repositories.insert(directory)

                // Also check for submodules
                let submodulePaths = findSubmodulePaths(in: directory, fileManager: fileManager)
                for submodulePath in submodulePaths {
                    print("GitService: Found submodule at: \(submodulePath)")
                    repositories.insert(submodulePath)
                }

                // Continue scanning for nested repos (don't return early)
            }

            // Scan subdirectories for git repos with depth limit
            let foundRepos = scanDirectory(
                directory,
                fileManager: fileManager,
                currentDepth: 0,
                maxDepth: maxDepth,
                skipFolders: skipFolders
            )
            for repo in foundRepos {
                repositories.insert(repo)
            }
        }

        print("GitService: Scan complete. Found \(repositories.count) repositories")
        return Array(repositories).sorted()
    }

    /// Parse .gitmodules file to find submodule paths
    private func findSubmodulePaths(in repoPath: String, fileManager: FileManager) -> [String] {
        let gitmodulesPath = (repoPath as NSString).appendingPathComponent(".gitmodules")

        guard fileManager.fileExists(atPath: gitmodulesPath),
              let content = try? String(contentsOfFile: gitmodulesPath, encoding: .utf8) else {
            return []
        }

        var submodulePaths: [String] = []
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("path = ") {
                let path = String(trimmed.dropFirst("path = ".count))
                let fullPath = (repoPath as NSString).appendingPathComponent(path)

                // Verify the submodule directory exists and has a .git
                let submoduleGitPath = (fullPath as NSString).appendingPathComponent(".git")
                if fileManager.fileExists(atPath: submoduleGitPath) {
                    submodulePaths.append(fullPath)
                }
            }
        }

        return submodulePaths
    }

    private func scanDirectory(
        _ directory: String,
        fileManager: FileManager,
        currentDepth: Int,
        maxDepth: Int,
        skipFolders: Set<String>
    ) -> Set<String> {
        var repositories = Set<String>()

        // Stop if max depth reached
        guard currentDepth < maxDepth else { return repositories }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directory)

            // Check if this directory is a git repo
            if contents.contains(".git") {
                print("GitService: Found git repo at: \(directory)")
                repositories.insert(directory)

                // Also check for submodules
                let submodulePaths = findSubmodulePaths(in: directory, fileManager: fileManager)
                for submodulePath in submodulePaths {
                    print("GitService: Found submodule at: \(submodulePath)")
                    repositories.insert(submodulePath)
                }

                // Don't scan inside .git folder, but continue scanning sibling directories
                // by returning here for this specific directory
                return repositories
            }

            for item in contents {
                // Skip hidden files
                if item.hasPrefix(".") {
                    continue
                }

                // Skip unwanted folders
                if skipFolders.contains(item) {
                    continue
                }

                let itemPath = (directory as NSString).appendingPathComponent(item)

                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    continue
                }

                // Recursively scan subdirectory
                let foundRepos = scanDirectory(
                    itemPath,
                    fileManager: fileManager,
                    currentDepth: currentDepth + 1,
                    maxDepth: maxDepth,
                    skipFolders: skipFolders
                )
                repositories.formUnion(foundRepos)
            }
        } catch {
            print("GitService: Error scanning \(directory): \(error)")
        }

        return repositories
    }

    public func fetchCommits(from repoPath: String, since: Date, limit: Int = 100, author: String? = nil) -> [GitActivity] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let sinceDate = dateFormatter.string(from: since)

        print("GitService: Fetching commits from \(repoPath) since \(sinceDate) (limit: \(limit), author: \(author ?? "all"))")

        // Build command arguments
        var args = ["log", "--pretty=format:%H|%s|%an|%ad", "--date=iso-strict", "--since=\(sinceDate)", "-n", "\(limit)"]
        if let author = author {
            args.append("--author=\(author)")
        }

        // Get commit log with limit
        guard let logOutput = runGitCommand(args, in: repoPath, timeout: 10.0) else {
            print("GitService: Failed to fetch commits from \(repoPath)")
            return []
        }

        let lines = logOutput.components(separatedBy: .newlines).filter { !$0.isEmpty }
        print("GitService: Found \(lines.count) commits in \(repoPath)")

        var activities: [GitActivity] = []
        let repoName = (repoPath as NSString).lastPathComponent

        for line in lines {
            let parts = line.components(separatedBy: "|")
            guard parts.count == 4 else {
                print("GitService: Skipping malformed line: \(line)")
                continue
            }

            let hash = parts[0]
            let message = parts[1]
            let author = parts[2]
            let dateString = parts[3]

            // Parse ISO date with multiple formats
            let isoFormatter = ISO8601DateFormatter()
            var date: Date?

            // Try strict format first
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            date = isoFormatter.date(from: dateString)

            // Fallback to format without fractional seconds
            if date == nil {
                isoFormatter.formatOptions = [.withInternetDateTime]
                date = isoFormatter.date(from: dateString)
            }

            // Fallback to basic ISO format
            if date == nil {
                isoFormatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
                date = isoFormatter.date(from: dateString)
            }

            guard let parsedDate = date else {
                print("GitService: Failed to parse date: \(dateString)")
                continue
            }

            // Get stats for this commit
            let stats = getCommitStats(hash: hash, in: repoPath)

            let activity = GitActivity(
                commitHash: hash,
                message: message,
                author: author,
                date: parsedDate,
                repositoryPath: repoPath,
                repositoryName: repoName,
                additions: stats.additions,
                deletions: stats.deletions,
                filesChanged: stats.filesChanged
            )
            activities.append(activity)
        }

        print("GitService: Successfully parsed \(activities.count) commits from \(repoPath)")
        return activities
    }

    public func getStats(for repoPath: String, since: Date? = nil, author: String? = nil) -> GitRepoStats {
        let commits = fetchCommits(from: repoPath, since: since ?? Date.distantPast, author: author)

        let totalCommits = commits.count
        let totalAdditions = commits.reduce(0) { $0 + $1.additions }
        let totalDeletions = commits.reduce(0) { $0 + $1.deletions }
        let totalFilesChanged = commits.reduce(0) { $0 + $1.filesChanged }

        // Calculate commit streak
        let streak = calculateCommitStreak(commits: commits)

        // Find most active day
        let mostActiveDay = findMostActiveDay(commits: commits)

        return GitRepoStats(
            totalCommits: totalCommits,
            totalAdditions: totalAdditions,
            totalDeletions: totalDeletions,
            commitStreak: streak,
            mostActiveDay: mostActiveDay,
            filesChanged: totalFilesChanged
        )
    }

    /// Get aggregated stats from multiple repositories
    public func getAggregatedStats(from commits: [GitActivity]) -> GitRepoStats {
        let totalCommits = commits.count
        let totalAdditions = commits.reduce(0) { $0 + $1.additions }
        let totalDeletions = commits.reduce(0) { $0 + $1.deletions }
        let totalFilesChanged = commits.reduce(0) { $0 + $1.filesChanged }

        let streak = calculateCommitStreak(commits: commits)
        let mostActiveDay = findMostActiveDay(commits: commits)

        return GitRepoStats(
            totalCommits: totalCommits,
            totalAdditions: totalAdditions,
            totalDeletions: totalDeletions,
            commitStreak: streak,
            mostActiveDay: mostActiveDay,
            filesChanged: totalFilesChanged
        )
    }

    private func getCommitStats(hash: String, in directory: String) -> (additions: Int, deletions: Int, filesChanged: Int) {
        guard let statsOutput = runGitCommand(
            ["show", "--shortstat", "--format=%b", hash],
            in: directory,
            timeout: 3.0
        ) else { return (0, 0, 0) }

        // Parse output like: " 3 files changed, 45 insertions(+), 12 deletions(-)"
        let lines = statsOutput.components(separatedBy: .newlines)
        guard let statsLine = lines.last(where: { $0.contains("changed") }) else {
            return (0, 0, 0)
        }

        var additions = 0
        var deletions = 0
        var filesChanged = 0

        let components = statsLine.components(separatedBy: ",")
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("insertion") {
                if let number = Int(trimmed.components(separatedBy: " ").first ?? "") {
                    additions = number
                }
            } else if trimmed.contains("deletion") {
                if let number = Int(trimmed.components(separatedBy: " ").first ?? "") {
                    deletions = number
                }
            } else if trimmed.contains("changed") {
                if let number = Int(trimmed.components(separatedBy: " ").first ?? "") {
                    filesChanged = number
                }
            }
        }

        return (additions, deletions, filesChanged)
    }

    private func calculateCommitStreak(commits: [GitActivity]) -> Int {
        guard !commits.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedDates = commits
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()
            .reversed()

        var streak = 1
        var currentDate = calendar.startOfDay(for: Date())

        for commitDate in sortedDates {
            if calendar.isDate(commitDate, inSameDayAs: currentDate) {
                continue
            } else if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate),
                      calendar.isDate(commitDate, inSameDayAs: previousDay) {
                streak += 1
                currentDate = previousDay
            } else {
                break
            }
        }

        return streak
    }

    private func findMostActiveDay(commits: [GitActivity]) -> Date? {
        guard !commits.isEmpty else { return nil }

        let calendar = Calendar.current
        var dayCounts: [Date: Int] = [:]

        for commit in commits {
            let day = calendar.startOfDay(for: commit.date)
            dayCounts[day, default: 0] += 1
        }

        return dayCounts.max(by: { $0.value < $1.value })?.key
    }

    private func runGitCommand(_ args: [String], in directory: String, timeout: TimeInterval = 5.0) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = URL(fileURLWithPath: directory)

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            print("GitService: Running git \(args.joined(separator: " ")) in \(directory) (timeout: \(timeout)s)")
            try process.run()

            // Add timeout mechanism
            let timeoutWorkItem = DispatchWorkItem {
                if process.isRunning {
                    print("GitService: Git command timed out after \(timeout)s, terminating")
                    process.terminate()
                }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

            process.waitUntilExit()
            timeoutWorkItem.cancel()

            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            if let errorOutput = String(data: errorData, encoding: .utf8), !errorOutput.isEmpty {
                print("GitService: Git stderr: \(errorOutput)")
            }

            guard process.terminationStatus == 0 else {
                print("GitService: Git command failed with status \(process.terminationStatus)")
                return nil
            }

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            return output
        } catch {
            print("GitService: Git command failed with error: \(error)")
            return nil
        }
    }
}
