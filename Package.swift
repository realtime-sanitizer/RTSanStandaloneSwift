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
            url: "https://github.com/realtime-sanitizer/rtsan-libs/releases/download/v20.1.1.2/rtsan.xcframework.zip",
            checksum: "f4f45abeec757adebc81f0c419da3aca0768357406cd7f8fee4c3a6289e50045"
        ),
        .binaryTarget(
            name: "rtsan-linux",
            path: "rtsan.artifactbundle"
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
