// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Transcribe",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "TranscribeCore", targets: ["TranscribeCore"]),
        .executable(name: "TranscribeCLI", targets: ["TranscribeCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "TranscribeCore",
            linkerSettings: [
                .linkedFramework("Speech")
            ]
        ),
        .executableTarget(
            name: "TranscribeCLI",
            dependencies: [
                "TranscribeCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "TranscribeCoreTests",
            dependencies: [
                "TranscribeCore"
            ]
        ),
        .testTarget(
            name: "TranscribeCLITests",
            dependencies: [
                "TranscribeCLI"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
