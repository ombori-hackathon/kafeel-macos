import Foundation

public enum DefaultCategories {
    public static let mappings: [String: (name: String, category: CategoryType)] = [
        // Productive - Development
        "com.apple.dt.Xcode": ("Xcode", .productive),
        "com.microsoft.VSCode": ("VS Code", .productive),
        "com.visualstudio.code.oss": ("VS Code", .productive),
        "com.jetbrains.intellij": ("IntelliJ IDEA", .productive),
        "com.jetbrains.intellij.ce": ("IntelliJ IDEA CE", .productive),
        "com.jetbrains.WebStorm": ("WebStorm", .productive),
        "com.jetbrains.pycharm": ("PyCharm", .productive),
        "com.apple.Terminal": ("Terminal", .productive),
        "com.googlecode.iterm2": ("iTerm", .productive),
        "dev.warp.Warp-Stable": ("Warp", .productive),
        "com.github.Electron": ("Electron App", .productive),

        // Productive - Design & Creative
        "com.figma.Desktop": ("Figma", .productive),
        "com.bohemiancoding.sketch3": ("Sketch", .productive),
        "com.adobe.Photoshop": ("Photoshop", .productive),
        "com.adobe.illustrator": ("Illustrator", .productive),

        // Productive - Productivity
        "com.apple.Notes": ("Notes", .productive),
        "notion.id": ("Notion", .productive),
        "com.linear": ("Linear", .productive),
        "com.apple.iCal": ("Calendar", .productive),
        "com.culturedcode.ThingsMac": ("Things", .productive),
        "com.todoist.mac.Todoist": ("Todoist", .productive),
        "md.obsidian": ("Obsidian", .productive),

        // Distracting - Social Media
        "com.twitter.twitter-mac": ("Twitter/X", .distracting),
        "com.facebook.Facebook": ("Facebook", .distracting),
        "com.instagram.Instagram": ("Instagram", .distracting),
        "com.reddit.Reddit": ("Reddit", .distracting),
        "com.tiktok.TikTok": ("TikTok", .distracting),

        // Distracting - Entertainment
        "com.spotify.client": ("Spotify", .distracting),
        "com.apple.TV": ("Apple TV", .distracting),
        "com.netflix.Netflix": ("Netflix", .distracting),
        "com.valvesoftware.steam": ("Steam", .distracting),
        "com.apple.Music": ("Music", .distracting),
        "tv.twitch.TwitchDesktop": ("Twitch", .distracting),
        "com.disney.DisneyPlus": ("Disney+", .distracting),

        // Neutral - System
        "com.apple.finder": ("Finder", .neutral),
        "com.apple.systempreferences": ("System Settings", .neutral),
        "com.apple.Safari": ("Safari", .neutral),
        "com.google.Chrome": ("Chrome", .neutral),
        "org.mozilla.firefox": ("Firefox", .neutral),
        "com.microsoft.edgemac": ("Edge", .neutral),
        "com.apple.mail": ("Mail", .neutral),
        "com.apple.Preview": ("Preview", .neutral),

        // Neutral - Communication (context dependent)
        "com.tinyspeck.slackmacgap": ("Slack", .neutral),
        "com.microsoft.teams": ("Teams", .neutral),
        "us.zoom.xos": ("Zoom", .neutral),
        "com.hnc.Discord": ("Discord", .neutral),
        "com.apple.MobileSMS": ("Messages", .neutral),
    ]

    public static func category(for bundleIdentifier: String) -> CategoryType? {
        mappings[bundleIdentifier]?.category
    }

    public static func appName(for bundleIdentifier: String) -> String? {
        mappings[bundleIdentifier]?.name
    }
}
