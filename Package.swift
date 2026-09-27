// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CleanStackMacOS",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CleanStackMacOS", targets: ["CleanStackMacOS"])
    ],
    targets: [
        .executableTarget(
            name: "CleanStackMacOS",
            path: "Sources/CleanStackMacOS"
        )
    ]
)
