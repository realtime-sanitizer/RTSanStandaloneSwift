// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "RTSanStandaloneSwift",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "RealtimeSanitizer", targets: ["RealtimeSanitizer", "RealtimeSanitizerCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0-latest")
    ],
    targets: [
        .binaryTarget(
            name: "rtsan",
            url: "https://github.com/realtime-sanitizer/rtsan-libs/releases/download/v20.1.1.3/rtsan.xcframework.zip",
            checksum: "d5e8aaf4663db0573e97d6a03a6140ab5e3dc7b60ae071c6c72c21a99002ad46"
        ),
        .binaryTarget(
            name: "rtsan-linux",
            url: "https://github.com/realtime-sanitizer/rtsan-libs/releases/download/v20.1.1.3/rtsan.artifactbundle.zip",
            checksum: "21e660f0a00559ba468ad87a710021ba9823f9b851d9c979d0a0fca536bd8d27"
        ),
        .macro(
            name: "RealtimeSanitizerMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "RealtimeSanitizerCore",
            dependencies: [
                .target(name: "rtsan", condition: .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .macCatalyst])),
                .target(name: "rtsan-linux", condition: .when(platforms: [.linux]))
            ]
        ),
        .target(
            name: "RealtimeSanitizer",
            dependencies: [
                "RealtimeSanitizerMacros",
                "RealtimeSanitizerCore"
            ]
        ),
        .executableTarget(
            name: "Playground",
            dependencies: ["RealtimeSanitizer", "RealtimeSanitizerCore"],
            path: "Examples/Playground"
        ),
        .executableTarget(
            name: "AVAudioEngine",
            dependencies: ["RealtimeSanitizer", "RealtimeSanitizerCore"],
            path: "Examples/AVAudioEngine"
        ),
        .testTarget(
            name: "RealtimeSanitizerTests",
            dependencies: [
                "RealtimeSanitizer",
                "RealtimeSanitizerCore",
                "RealtimeSanitizerMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ]
)
