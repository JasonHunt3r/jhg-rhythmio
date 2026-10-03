// swift-tools-version: 6.0
// PopoverKit: the Mac's own popover, anchored to a view, that stays until
// the app closes it (spec/popoverkit.md in RhythmIO) — several at once,
// each able to let clicks through to what's under it, its content swapped
// in place. Its own package, beside PaneKit and ListKit, so an app can have
// any one without the others.
//
//   swift test                    the tests
//   swift run PopoverHarness      the test app
import PackageDescription

let package = Package(
    name: "PopoverKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PopoverKit", targets: ["PopoverKit"]),
        .executable(name: "PopoverHarness", targets: ["PopoverHarness"]),
    ],
    targets: [
        .target(name: "PopoverKit"),
        .executableTarget(name: "PopoverHarness", dependencies: ["PopoverKit"], path: "Harness"),
        .testTarget(name: "PopoverKitTests", dependencies: ["PopoverKit"]),
    ]
)
