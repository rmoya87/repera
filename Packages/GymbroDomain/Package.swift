// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GymbroDomain",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26),
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
