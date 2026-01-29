import Foundation
import SwiftUI

public enum URLCategory: String, CaseIterable, Codable {
    case work
    case social
    case email
    case entertainment
    case shopping
    case news
    case other

    public var displayName: String {
        switch self {
        case .work: return "Work"
        case .social: return "Social"
        case .email: return "Email"
        case .entertainment: return "Entertainment"
        case .shopping: return "Shopping"
        case .news: return "News"
        case .other: return "Other"
        }
    }

    public var color: Color {
        switch self {
        case .work: return .green
        case .social: return .blue
        case .email: return .purple
        case .entertainment: return .red
        case .shopping: return .orange
        case .news: return .cyan
        case .other: return .gray
        }
    }

    public var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .social: return "person.2.fill"
        case .email: return "envelope.fill"
        case .entertainment: return "play.tv.fill"
        case .shopping: return "cart.fill"
        case .news: return "newspaper.fill"
        case .other: return "globe"
        }
    }

    /// Categorize a URL based on its domain
    public static func categorize(url: String) -> URLCategory {
        let lowercased = url.lowercased()

        // Work domains
        let workDomains = [
            "github.com", "gitlab.com", "bitbucket.org",
            "stackoverflow.com", "stackexchange.com",
            "jira.", "atlassian.", "confluence.",
            "notion.so", "linear.app", "asana.com", "trello.com",
            "figma.com", "sketch.com",
            "aws.amazon.com", "console.cloud.google.com", "portal.azure.com",
            "docs.google.com", "sheets.google.com", "slides.google.com",
            "developer.apple.com", "developer.mozilla.org"
        ]

        for domain in workDomains {
            if lowercased.contains(domain) {
                return .work
            }
        }

        // Social domains
        let socialDomains = [
            "twitter.com", "x.com", "facebook.com", "instagram.com",
            "linkedin.com", "reddit.com", "tiktok.com",
            "snapchat.com", "pinterest.com", "tumblr.com",
            "discord.com", "slack.com", "whatsapp.com", "telegram.org"
        ]

        for domain in socialDomains {
            if lowercased.contains(domain) {
                return .social
            }
        }

        // Email domains
        let emailDomains = [
            "mail.google.com", "gmail.com",
            "outlook.com", "outlook.live.com", "outlook.office.com",
            "mail.yahoo.com", "mail.proton.me", "protonmail.com",
            "fastmail.com", "hey.com"
        ]

        for domain in emailDomains {
            if lowercased.contains(domain) {
                return .email
            }
        }

        // Entertainment domains
        let entertainmentDomains = [
            "youtube.com", "netflix.com", "hulu.com", "disneyplus.com",
            "hbomax.com", "primevideo.com", "twitch.tv",
            "spotify.com", "music.apple.com", "soundcloud.com",
            "vimeo.com", "dailymotion.com",
            "imdb.com", "rottentomatoes.com"
        ]

        for domain in entertainmentDomains {
            if lowercased.contains(domain) {
                return .entertainment
            }
        }

        // Shopping domains
        let shoppingDomains = [
            "amazon.com", "ebay.com", "walmart.com", "target.com",
            "etsy.com", "aliexpress.com", "shopify.com",
            "bestbuy.com", "newegg.com"
        ]

        for domain in shoppingDomains {
            if lowercased.contains(domain) {
                return .shopping
            }
        }

        // News domains
        let newsDomains = [
            "news.google.com", "news.ycombinator.com",
            "cnn.com", "bbc.com", "nytimes.com", "washingtonpost.com",
            "theguardian.com", "reuters.com", "apnews.com",
            "techcrunch.com", "theverge.com", "arstechnica.com", "wired.com"
        ]

        for domain in newsDomains {
            if lowercased.contains(domain) {
                return .news
            }
        }

        return .other
    }
}
