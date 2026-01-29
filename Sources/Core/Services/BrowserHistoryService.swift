import Foundation
import SQLite3

/// Service for reading browser history from Safari and Chrome SQLite databases.
/// Note: Requires Full Disk Access permission in System Settings for Safari history.
@MainActor
public final class BrowserHistoryService {
    public static let shared = BrowserHistoryService()

    private init() {}

    // MARK: - Public API

    /// Fetch browsing history from all available browsers
    public func fetchHistory(since: Date, limit: Int = 500) -> [BrowsingActivity] {
        var allHistory: [BrowsingActivity] = []

        // Try Safari
        if let safariHistory = fetchSafariHistory(since: since, limit: limit) {
            allHistory.append(contentsOf: safariHistory)
        }

        // Try Chrome
        if let chromeHistory = fetchChromeHistory(since: since, limit: limit) {
            allHistory.append(contentsOf: chromeHistory)
        }

        // Sort by visit time, most recent first
        return allHistory.sorted { $0.visitTime > $1.visitTime }
    }

    /// Check if we have permission to read browser history
    public func checkPermissions() -> (safari: Bool, chrome: Bool) {
        let safariPath = safariHistoryPath
        let chromePath = chromeHistoryPath

        let safariAccess = FileManager.default.isReadableFile(atPath: safariPath)
        let chromeAccess = FileManager.default.isReadableFile(atPath: chromePath)

        return (safariAccess, chromeAccess)
    }

    // MARK: - Safari History

    private var safariHistoryPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Safari/History.db"
    }

    private func fetchSafariHistory(since: Date, limit: Int) -> [BrowsingActivity]? {
        let dbPath = safariHistoryPath

        guard FileManager.default.isReadableFile(atPath: dbPath) else {
            print("BrowserHistoryService: Cannot read Safari history (Full Disk Access required)")
            return nil
        }

        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            print("BrowserHistoryService: Failed to open Safari history database")
            return nil
        }
        defer { sqlite3_close(db) }

        // Safari stores timestamps as seconds since 2001-01-01 (Core Data reference date)
        let coreDataEpoch = Date(timeIntervalSinceReferenceDate: 0)
        let sinceTimestamp = since.timeIntervalSince(coreDataEpoch)

        let query = """
            SELECT
                history_items.url,
                history_visits.title,
                history_visits.visit_time
            FROM history_visits
            JOIN history_items ON history_items.id = history_visits.history_item
            WHERE history_visits.visit_time > ?
            ORDER BY history_visits.visit_time DESC
            LIMIT ?
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("BrowserHistoryService: Failed to prepare Safari query")
            return nil
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_double(statement, 1, sinceTimestamp)
        sqlite3_bind_int(statement, 2, Int32(limit))

        var history: [BrowsingActivity] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            let url = String(cString: sqlite3_column_text(statement, 0))
            let title = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? url
            let visitTimeInterval = sqlite3_column_double(statement, 2)

            // Convert Core Data timestamp to Date
            let visitTime = Date(timeIntervalSinceReferenceDate: visitTimeInterval)

            let activity = BrowsingActivity(
                url: url,
                title: title,
                visitTime: visitTime,
                browser: "Safari"
            )
            history.append(activity)
        }

        print("BrowserHistoryService: Fetched \(history.count) Safari history items")
        return history
    }

    // MARK: - Chrome History

    private var chromeHistoryPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/Google/Chrome/Default/History"
    }

    private func fetchChromeHistory(since: Date, limit: Int) -> [BrowsingActivity]? {
        let dbPath = chromeHistoryPath

        guard FileManager.default.fileExists(atPath: dbPath) else {
            print("BrowserHistoryService: Chrome history not found")
            return nil
        }

        // Chrome locks its history file, so we need to copy it first
        let tempPath = NSTemporaryDirectory() + "chrome_history_\(UUID().uuidString).db"
        do {
            try FileManager.default.copyItem(atPath: dbPath, toPath: tempPath)
        } catch {
            print("BrowserHistoryService: Failed to copy Chrome history: \(error)")
            return nil
        }
        defer {
            try? FileManager.default.removeItem(atPath: tempPath)
        }

        var db: OpaquePointer?
        guard sqlite3_open_v2(tempPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            print("BrowserHistoryService: Failed to open Chrome history database")
            return nil
        }
        defer { sqlite3_close(db) }

        // Chrome stores timestamps as microseconds since 1601-01-01 (Windows FILETIME)
        // Convert to Unix timestamp: subtract 11644473600 seconds (difference between 1601 and 1970)
        // Then convert from microseconds to seconds
        let windowsToUnixOffset: Int64 = 11644473600
        let sinceChrome = (Int64(since.timeIntervalSince1970) + windowsToUnixOffset) * 1_000_000

        let query = """
            SELECT url, title, last_visit_time, visit_count
            FROM urls
            WHERE last_visit_time > ?
            ORDER BY last_visit_time DESC
            LIMIT ?
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("BrowserHistoryService: Failed to prepare Chrome query")
            return nil
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int64(statement, 1, sinceChrome)
        sqlite3_bind_int(statement, 2, Int32(limit))

        var history: [BrowsingActivity] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            let url = String(cString: sqlite3_column_text(statement, 0))
            let title = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? url
            let lastVisitChrome = sqlite3_column_int64(statement, 2)

            // Convert Chrome timestamp to Date
            let unixTimestamp = TimeInterval(lastVisitChrome / 1_000_000 - windowsToUnixOffset)
            let visitTime = Date(timeIntervalSince1970: unixTimestamp)

            let activity = BrowsingActivity(
                url: url,
                title: title,
                visitTime: visitTime,
                browser: "Chrome"
            )
            history.append(activity)
        }

        print("BrowserHistoryService: Fetched \(history.count) Chrome history items")
        return history
    }

    // MARK: - Statistics

    /// Get browsing statistics grouped by category
    public func getCategoryStats(from activities: [BrowsingActivity]) -> [URLCategory: Int] {
        var stats: [URLCategory: Int] = [:]

        for activity in activities {
            stats[activity.category, default: 0] += 1
        }

        return stats
    }

    /// Get most visited domains
    public func getTopDomains(from activities: [BrowsingActivity], limit: Int = 10) -> [(domain: String, count: Int)] {
        var domainCounts: [String: Int] = [:]

        for activity in activities {
            domainCounts[activity.domain, default: 0] += 1
        }

        return domainCounts
            .map { (domain: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }
}
