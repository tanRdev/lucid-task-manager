// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Lucid",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Lucid",
            targets: ["Lucid"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Lucid",
            dependencies: [],
            path: "Lucid",
            exclude: [
                "Info.plist",
                "Lucid.entitlements"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "LucidTests",
            dependencies: ["Lucid"],
            path: "LucidTests",
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
