// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "ReperaDomain",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26),
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
