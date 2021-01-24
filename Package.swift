// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPAudio",
    platforms: [
        .iOS(SupportedPlatform.IOSVersion.v12),
        .macOS(SupportedPlatform.MacOSVersion.v10_13),
    ],
    products: [
        .library(
            name: "SPAudio",
            targets: ["SPAudio"]
        ),
    ],
    dependencies: [
        .package(
            name: "ReactiveSwift",
            url: "https://github.com/ReactiveCocoa/ReactiveSwift.git",
            from: "6.1.0"
        ),
        .package(
            url: "https://github.com/BillPiotrowski/SPCommon.git",
            Package.Dependency.Requirement.branch("main")
        ),
        .package(
            url: "https://github.com/BillPiotrowski/WPNowPlayable.git",
            Package.Dependency.Requirement.branch("main")
        ),
        .package(
            name: "Promises",
            url: "https://github.com/google/promises.git",
            "1.2.8" ..< "1.3.0"
        ),
        .package(
            url: "https://github.com/BillPiotrowski/AudioKitLite",
            Package.Dependency.Requirement.branch("main")
        ),
    ],
    targets: [
        .target(
            name: "SPAudio",
            dependencies: [
                "SPCommon",
                "WPNowPlayable",
                "ReactiveSwift",
                "AudioKitLite",
                .product(name: "Promises", package: "Promises"),
            ]
        ),
//        .binaryTarget(
//            name: "MIKMIDI",
//            path: "MIKMIDI.xcframework"
//        ),
        .testTarget(
            name: "SPAudioTests",
            dependencies: [
                "SPAudio",
                "AudioKitLite"
            ]
        ),
    ]
)
