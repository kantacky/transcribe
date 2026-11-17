// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Transcribe",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "TranscribeCore", targets: ["TranscribeCore"]),
        .library(name: "TranscribeApp", targets: ["TranscribeApp"]),
        .executable(name: "TranscribeCLI", targets: ["TranscribeCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/FluidInference/FluidAudio.git", exact: "0.17.7"),
    ],
    targets: [
        .target(
            name: "TranscribeDomain"
        ),
        .target(
            name: "TranscribeExport",
            dependencies: [
                "TranscribeDomain"
            ]
        ),
        .target(
            name: "TranscribeCore",
            dependencies: [
                "TranscribeDomain",
                .product(name: "FluidAudio", package: "FluidAudio"),
            ],
            linkerSettings: [
                .linkedFramework("Speech")
            ]
        ),
        .target(
            name: "TranscribeApp",
            dependencies: [
                "TranscribeCore",
                "TranscribeDomain",
                "TranscribeExport",
            ],
            resources: [
                .process("Localizable.xcstrings")
            ]
        ),
        .executableTarget(
            name: "TranscribeCLI",
            dependencies: [
                "TranscribeCore",
                "TranscribeDomain",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "TranscribeCoreTests",
            dependencies: [
                "TranscribeCore",
                "TranscribeDomain",
            ]
        ),
        .testTarget(
            name: "TranscribeAppTests",
            dependencies: [
                "TranscribeApp"
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
