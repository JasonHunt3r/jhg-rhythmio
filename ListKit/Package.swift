// swift-tools-version: 6.0
// ListKit: pro-level lists for Mac apps that can't be a SwiftUI `List`
// (spec/listkit.md in RhythmIO) — keyboard navigation, outline chevrons
// and indents, inline rename, and the rows' accessibility. Its own package,
// beside PaneKit, so an app can have either without the other.
//
//   swift test                 the tests
//   swift run ListHarness      the test app
import PackageDescription

let package = Package(
    name: "ListKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ListKit", targets: ["ListKit"]),
        .executable(name: "ListHarness", targets: ["ListHarness"]),
    ],
    targets: [
        .target(name: "ListKit"),
        .executableTarget(name: "ListHarness", dependencies: ["ListKit"], path: "Harness"),
        .testTarget(name: "ListKitTests", dependencies: ["ListKit"]),
    ]
)
