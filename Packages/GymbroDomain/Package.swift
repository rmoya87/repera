// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "GymbroDomain",
    platforms: [
        .iOS(.v27),
        .watchOS(.v27),
        .macOS(.v27),
    ],
    products: [
        .library(name: "GymbroDomain", targets: ["GymbroDomain"]),
    ],
    targets: [
        .target(
            name: "GymbroDomain",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "GymbroDomainTests",
            dependencies: ["GymbroDomain"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
