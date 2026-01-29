import SwiftUI
import AppKit
import SwiftData
import KafeelCore

@main
struct KafeelApp: App {
    @State private var appState: AppState
    @State private var menuBarManager = MenuBarManager()

    let modelContainer: ModelContainer

    init() {
        // Check for icon generation flag
        if CommandLine.arguments.contains("--generate-icons") {
            Self.generateIcons()
            exit(0)
        }

        // Required for swift run to show GUI window
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        // Initialize SwiftData model container
        do {
            modelContainer = try ModelContainer(
                for: ActivityLog.self, AppCategory.self, AppSettings.self, GitActivity.self,
                // Flow Score models
                DailyScore.self, Streak.self, Achievement.self, PersonalRecord.self, UserProfile.self, MeetingSession.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Initialize AppState with model context
        _appState = State(initialValue: AppState(modelContext: modelContainer.mainContext))
    }

    var body: some Scene {
        WindowGroup(id: "MainWindow") {
            ContentView()
                .environment(appState)
                .modelContainer(modelContainer)
                .task {
                    // Seed default data if needed
                    await seedDefaultDataIfNeeded()
                    // Start activity tracking when app launches
                    appState.startTracking()
                    // Setup menu bar
                    menuBarManager.setup(appState: appState)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Kafeel") {
                    NSApp.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "Kafeel",
                            .applicationVersion: "1.0.0",
                            .version: "Build 1",
                            .credits: NSAttributedString(string: "Activity Tracker for macOS")
                        ]
                    )
                }
            }
        }

        // Settings window
        Settings {
            SettingsView()
                .modelContainer(modelContainer)
        }

        // About window (using custom icon)
        Window("About Kafeel", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    @MainActor
    private func seedDefaultDataIfNeeded() async {
        let context = modelContainer.mainContext

        // Seed default categories
        let categoryDescriptor = FetchDescriptor<AppCategory>()
        let existingCategoryCount = (try? context.fetchCount(categoryDescriptor)) ?? 0

        if existingCategoryCount == 0 {
            for (bundleId, mapping) in DefaultCategories.mappings {
                let category = AppCategory(
                    bundleIdentifier: bundleId,
                    appName: mapping.name,
                    category: mapping.category,
                    isDefault: true
                )
                context.insert(category)
            }
            print("Seeded \(DefaultCategories.mappings.count) default app categories")
        }

        // Seed default settings
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        let existingSettingsCount = (try? context.fetchCount(settingsDescriptor)) ?? 0

        if existingSettingsCount == 0 {
            let settings = AppSettings()
            context.insert(settings)
            print("Seeded default app settings")
        }

        try? context.save()
    }

    /// Generate app icon PNG files
    private static func generateIcons() {
        print("Generating app icons...")

        let outputPath: String
        if CommandLine.arguments.count > 2 {
            outputPath = CommandLine.arguments[2]
        } else {
            outputPath = "./AppIcon.appiconset"
        }

        let outputURL = URL(fileURLWithPath: outputPath)

        do {
            // Create output directory if needed
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

            // Generate icons
            try IconGenerator.generateAppIcons(outputDirectory: outputURL)

            // Generate Contents.json
            try generateContentsJSON(at: outputURL)

            print("\nSuccess! Icons generated at: \(outputURL.path)")
            print("\nTo use these icons:")
            print("1. Create an Xcode project or add Assets.xcassets to your project")
            print("2. Copy the AppIcon.appiconset folder into Assets.xcassets/")
            print("3. The icons will be automatically detected by Xcode")
        } catch {
            print("Error generating icons: \(error)")
            exit(1)
        }
    }

    /// Generate Contents.json for the icon set
    private static func generateContentsJSON(at directory: URL) throws {
        let json = """
        {
          "images" : [
            {
              "filename" : "icon_16x16.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "16x16"
            },
            {
              "filename" : "icon_16x16@2x.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "16x16"
            },
            {
              "filename" : "icon_32x32.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "32x32"
            },
            {
              "filename" : "icon_32x32@2x.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "32x32"
            },
            {
              "filename" : "icon_128x128.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "128x128"
            },
            {
              "filename" : "icon_128x128@2x.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "128x128"
            },
            {
              "filename" : "icon_256x256.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "256x256"
            },
            {
              "filename" : "icon_256x256@2x.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "256x256"
            },
            {
              "filename" : "icon_512x512.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "512x512"
            },
            {
              "filename" : "icon_512x512@2x.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "512x512"
            }
          ],
          "info" : {
            "author" : "kafeel-icon-generator",
            "version" : 1
          }
        }
        """

        let fileURL = directory.appendingPathComponent("Contents.json")
        try json.write(to: fileURL, atomically: true, encoding: .utf8)
        print("Generated: Contents.json")
    }
}
