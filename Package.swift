// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

#if arch(x86_64)
let path = "x86_64"
#else
let path = "aarch64"
#endif

let package = Package(
    name: "RTSanStandaloneSwift",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(name: "RealtimeSanitizer", targets: ["RealtimeSanitizer", "RealtimeSanitizerCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest")
    ],
    targets: [
        .binaryTarget(name: "rtsan", path: "Binary/rtsan.xcframework"),
        .macro(
            name: "RealtimeSanitizerMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "RealtimeSanitizerCBindings",
            path: "Sources/RealtimeSanitizerCBindings",
            cSettings: [.headerSearchPath("../../rtsan/include/rtsan_standalone")]
        ),
        .target(
            name: "RealtimeSanitizerCore",
            dependencies: [
                .target(name: "rtsan", condition: .when(platforms: [.macOS])),
                .target(name: "RealtimeSanitizerCBindings", condition: .when(platforms: [.linux]))
            ],
            linkerSettings: [
                .unsafeFlags(["-L", "./Binary/\(path)", "-lrtsan"], .when(platforms: [.linux])),
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
