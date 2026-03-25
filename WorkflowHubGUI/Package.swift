// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WorkflowHubGUI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "WorkflowHubGUI",
            targets: ["WorkflowHubGUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
    ],
    targets: [
        .executableTarget(
            name: "WorkflowHubGUI",
            dependencies: [
                "Starscream",
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)