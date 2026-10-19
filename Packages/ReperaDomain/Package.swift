// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "ReperaDomain",
    platforms: [
        .iOS(.v27),
        .watchOS(.v27),
        .macOS(.v27),
    ],
    products: [
        .library(name: "ReperaDomain", targets: ["ReperaDomain"]),
    ],
    targets: [
        .target(
            name: "ReperaDomain",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "ReperaDomainTests",
            dependencies: ["ReperaDomain"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
