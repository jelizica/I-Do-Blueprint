// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Core",
            targets: ["Models", "Networking", "Common", "Repositories"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Models",
            dependencies: []
        ),
        .target(
            name: "Common",
            dependencies: []
        ),
        .target(
            name: "Networking",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                "Common"
            ]
        ),
        .target(
            name: "Repositories",
            dependencies: [
                "Models",
                "Networking",
                "Common",
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        ),
        .testTarget(
            name: "ModelsTests",
            dependencies: ["Models"]
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"]
        ),
        .testTarget(
            name: "RepositoriesTests",
            dependencies: ["Repositories"]
        )
    ]
)
