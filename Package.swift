// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KafeelClient",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "KafeelClient", targets: ["KafeelClient"]),
        .library(name: "KafeelCore", targets: ["KafeelCore"])
    ],
    targets: [
        .target(
            name: "KafeelCore",
            path: "Sources/Core"
        ),
        .executableTarget(
            name: "KafeelClient",
            dependencies: ["KafeelCore"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "KafeelClientTests",
            dependencies: ["KafeelCore"],
            path: "Tests"
        )
    ]
)
