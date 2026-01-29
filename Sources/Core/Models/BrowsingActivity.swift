import Foundation
import SwiftData

@Model
public final class BrowsingActivity {
    public var id: UUID
    public var url: String
    public var title: String
    public var visitTime: Date
    public var durationSeconds: Int
    public var browser: String  // "Safari", "Chrome", etc.
    public var categoryRaw: String

    public var category: URLCategory {
        get { URLCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    public var domain: String {
        guard let urlObj = URL(string: url),
              let host = urlObj.host else {
            return url
        }
        // Remove www. prefix
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        return host
    }

    public var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(visitTime)

        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }

    public init(
        url: String,
        title: String,
        visitTime: Date,
        durationSeconds: Int = 0,
        browser: String,
        category: URLCategory? = nil
    ) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.visitTime = visitTime
        self.durationSeconds = durationSeconds
        self.browser = browser
        self.categoryRaw = (category ?? URLCategory.categorize(url: url)).rawValue
    }
}
