// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPAudio",
    // SETTING TO v12 because, although AudioKit says it supports v11, it does not and there are 100s of unit test errors.
    platforms: [.iOS(SupportedPlatform.IOSVersion.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SPAudio",
            targets: ["SPAudio"]),
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
            url: "https://github.com/AudioKit/AudioKit",
            Package.Dependency.Requirement.branch("v5-main")
        )
        
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SPAudio",
            dependencies: ["SPCommon", "ReactiveSwift", "AudioKit", "WPNowPlayable"]),
        .testTarget(
            name: "SPAudioTests",
            dependencies: ["SPAudio"]),
    ]
)
