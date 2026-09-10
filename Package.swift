// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ClipboardHistory",
    platforms: [.macOS(.v26)],
    targets: [
        .target(
            name: "ClipboardHistoryCore"
        ),
        .executableTarget(
            name: "ClipboardHistory",
            dependencies: ["ClipboardHistoryCore"]
        ),
        .testTarget(
            name: "ClipboardHistoryCoreTests",
            dependencies: ["ClipboardHistoryCore"],
            swiftSettings: [
                .unsafeFlags(["-plugin-path", "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing"])
            ]
        ),
    ]
)
