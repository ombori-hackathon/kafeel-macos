# KafeelClient - macOS Activity Tracker

Native macOS app for tracking app usage, calculating focus scores, and displaying productivity analytics.

## Commands
```bash
swift build          # Build the app
swift run KafeelClient  # Run with GUI window
swift test           # Run all tests (35 tests)
```

## Architecture

### Module Structure (Swift Package Manager)
```
Package.swift defines two modules:
├── KafeelCore (library)     # Models + Services
│   └── Sources/Core/
└── KafeelClient (executable) # App + Views
    └── Sources/App/
```

**Important**: App files must `import KafeelCore` to access models and services.

### Directory Structure
```
Sources/
├── Core/                    # KafeelCore module
│   ├── Models/
│   │   ├── ActivityLog.swift      # SwiftData @Model for activity records
│   │   ├── AppCategory.swift      # App categorization model
│   │   ├── AppSettings.swift      # User preferences model
│   │   ├── CategoryType.swift     # Enum: productive/distracting/neutral
│   │   └── DefaultCategories.swift # 47 pre-defined app categories
│   └── Services/
│       ├── PersistenceService.swift    # SwiftData CRUD singleton
│       ├── ActivityMonitor.swift       # NSWorkspace app tracking
│       └── FocusScoreCalculator.swift  # Score algorithm
│
└── App/                     # KafeelClient module
    ├── KafeelApp.swift      # @main entry point
    ├── AppState.swift       # @Observable global state
    ├── ContentView.swift    # Navigation shell (sidebar)
    ├── Views/
    │   ├── Dashboard/       # DashboardView, FocusScoreCard, AppUsageChart
    │   └── Settings/        # SettingsView, CategoryManagerView
    └── Components/
        └── SecureActionButton.swift  # LocalAuthentication wrapper

Tests/
├── FocusScoreCalculatorTests.swift  # 15 tests
├── PersistenceServiceTests.swift    # 10 tests
└── ActivityMonitorTests.swift       # 10 tests
```

## Key Patterns & Learnings

### Swift 6 Concurrency
- Use `@MainActor` on classes that touch UI or SwiftData
- `@Observable` (not `ObservableObject`) for modern state management
- Avoid `deinit` in `@MainActor` classes - use explicit cleanup methods instead
- For async calls from `@MainActor` to `@MainActor`, no `await` needed

### SwiftData
- Models must be `public` if accessed from other modules
- Use `@Attribute(.unique)` for unique constraints
- ModelContainer setup: `ModelContainer(for: Model1.self, Model2.self, ...)`
- In-memory stores for tests: `ModelConfiguration(isStoredInMemoryOnly: true)`

### Multi-Module SPM Package
```swift
// Package.swift pattern for library + executable + tests
.target(name: "KafeelCore", path: "Sources/Core"),
.executableTarget(name: "KafeelClient", dependencies: ["KafeelCore"], path: "Sources/App"),
.testTarget(name: "KafeelClientTests", dependencies: ["KafeelCore"], path: "Tests")
```

### NSWorkspace App Monitoring
```swift
// Track frontmost app changes
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification,
    object: nil, queue: .main
) { notification in
    let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
}
```

### LocalAuthentication (Password Protection)
```swift
import LocalAuthentication
let context = LAContext()
let success = try await context.evaluatePolicy(
    .deviceOwnerAuthentication,  // Allows password, Touch ID, Face ID
    localizedReason: "Reason shown to user"
)
```

### Swift Charts
```swift
import Charts
Chart(data, id: \.id) { item in
    BarMark(x: .value("Time", item.minutes), y: .value("App", item.name))
        .foregroundStyle(item.color)
}
```

### App Icons
App icon assets generated programmatically:
- **SwiftUI Views**: `Sources/App/Assets/AppIconView.swift`
  - `AppIconView(size:)` - Full-color gradient icon with bar chart
  - `MenuBarIconView(size:)` - Monochrome template for menu bar
- **PNG Set**: `AppIcon.appiconset/` - All macOS sizes (16x16 to 1024x1024)
- **macOS Bundle**: `Kafeel.icns` - Ready for .app bundles
- **Generator**: `generate_icons.py` - Regenerate icons anytime
```swift
// Usage in code
AppIconView(size: 32)  // Sidebar
AppIconView(size: 128) // About screen
MenuBarIconView(size: 18) // Menu bar
```
See `README_ICONS.md` for complete documentation.

## Focus Score Algorithm
```
baseScore = (productiveSeconds * 1.0 + neutralSeconds * 0.5) / totalSeconds * 100
switchPenalty = max(0, switchesPerHour - 10) * 0.5
finalScore = clamp(baseScore - switchPenalty, 0, 100)
```

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| "Cannot find type in scope" across modules | Make type AND its init/methods `public` in Core module |
| "No such module 'KafeelCore'" in IDE | Build once with `swift build` - IDE catches up |
| Test target can't find types | Depend on library target, not executable |
| MainActor isolation errors in deinit | Use explicit `cleanup()` method instead |
| SwiftData crashes in tests | Use in-memory ModelConfiguration |

## API Integration (Optional)
Backend at http://localhost:8000 for cloud sync (not yet implemented).
