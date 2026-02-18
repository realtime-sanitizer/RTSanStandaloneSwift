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
            url: "https://github.com/jcavar/rtsan-libs/releases/download/v0.0.0.18/rtsan.xcframework.zip",
            checksum: "db857aeed179b7d4fa640c337e05e0f9084a2a4268b04e1936b4056d815aea49"
        ),
        .binaryTarget(
            name: "rtsan-linux",
            url: "https://github.com/jcavar/rtsan-libs/releases/download/v0.0.0.18/rtsan.artifactbundle.zip",
            checksum: "77392a78dc329d19e57c5ca7a5cb80da7da5ef87fba0c559a998e9c81190c621"
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
            ],
            swiftSettings: [.enableExperimentalFeature("Extern")]
        )
    ]
)
