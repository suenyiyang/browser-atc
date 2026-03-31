// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BrowserATC",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "BrowserATC",
            path: "Sources/BrowserATC"
        )
    ]
)
