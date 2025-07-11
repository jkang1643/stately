// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "stately",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "stately",
            targets: ["stately"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "stately",
            path: "stately"
        ),
    ]
)