// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Match3Kit",
    products: [
        .library(name: "Match3Kit", targets: ["Match3Kit"])
    ],
    targets: [
        .target(name: "Match3Kit"),
        .testTarget(name: "Match3KitTests"),
    ],
    swiftLanguageVersions: [.v5]
)
