// swift-tools-version:5.9
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
            resources: [
                .copy("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "LucidTests",
            dependencies: ["Lucid"],
            path: "LucidTests"
        )
    ]
)
