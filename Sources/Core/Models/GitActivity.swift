import Foundation
import SwiftData

@Model
public final class GitActivity {
    public var id: UUID
    public var commitHash: String
    public var message: String
    public var author: String
    public var date: Date
    public var repositoryPath: String
    public var repositoryName: String
    public var additions: Int
    public var deletions: Int
    public var filesChanged: Int

    public var shortHash: String {
        String(commitHash.prefix(7))
    }

    public var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        let weeks = Int(interval / 604800)

        if weeks > 0 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if days > 0 {
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
        commitHash: String,
        message: String,
        author: String,
        date: Date,
        repositoryPath: String,
        repositoryName: String,
        additions: Int = 0,
        deletions: Int = 0,
        filesChanged: Int = 0
    ) {
        self.id = UUID()
        self.commitHash = commitHash
        self.message = message
        self.author = author
        self.date = date
        self.repositoryPath = repositoryPath
        self.repositoryName = repositoryName
        self.additions = additions
        self.deletions = deletions
        self.filesChanged = filesChanged
    }
}
