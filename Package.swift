import PackageDescription

let package = Package(
    name: "Match3Kit",
    dependencies: [],
    targets: [
        .target(
            name: "Match3Kit",
            dependencies: []
        ),
        .testTarget(
            name: "Match3KitTests",
            dependencies: []
        ),
    ]
)
