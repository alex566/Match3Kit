// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "Match3Kit",
    platforms: [.iOS(.v13), .macOS(.v11), .tvOS(.v13)],
    products: [
        .library(name: "Match3Kit", targets: ["Match3Kit"])
    ],
    targets: [
        .target(name: "Match3Kit"),
        .testTarget(name: "Match3KitTests", dependencies: ["Match3Kit"])
    ],
    swiftLanguageVersions: [.v5]
)
