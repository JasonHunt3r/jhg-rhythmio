// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RhythmIO",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "RhythmIOCore", targets: ["RhythmIOCore"]),
        .library(name: "RhythmIOPlayback", targets: ["RhythmIOPlayback"]),
        .library(name: "RhythmBGCore", targets: ["RhythmBGCore"]),
        .executable(name: "RhythmIOApp", targets: ["RhythmIOApp"]),
        .executable(name: "mio", targets: ["mio"]),
    ],
    dependencies: [
        .package(name: "PaneKit", path: "PaneKit"),
        .package(name: "ListKit", path: "ListKit"),
        .package(name: "PopoverKit", path: "PopoverKit"),
    ],
    targets: [
        .target(name: "RhythmIOCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .target(name: "RhythmIOPlayback", dependencies: ["RhythmIOCore"]),
        .target(name: "RhythmBGCore", dependencies: ["RhythmIOCore"]),
        // Info.plist is generated into the sources folder by XcodeGen (the app
        // bundle is built by Xcode; see project.yml), so SwiftPM must be told
        // it isn't a resource.
        .executableTarget(name: "RhythmIOApp",
                          dependencies: ["RhythmIOCore", "RhythmIOPlayback", "RhythmBGCore", "PaneKit", "ListKit", "PopoverKit"],
                          exclude: ["Info.plist"]),
        .executableTarget(name: "mio", dependencies: ["RhythmIOCore"]),
        .testTarget(name: "RhythmIOCoreTests", dependencies: ["RhythmIOCore"]),
        .testTarget(name: "RhythmBGCoreTests", dependencies: ["RhythmBGCore", "RhythmIOCore"]),
    ]
)
