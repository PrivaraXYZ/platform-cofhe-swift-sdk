// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CoFheSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "CoFheSDK",
            targets: ["CoFheSDK"]
        ),
    ],
    targets: [
        .target(
            name: "CoFheSDK"
        ),
        .testTarget(
            name: "CoFheSDKTests",
            dependencies: ["CoFheSDK"]
        ),
    ]
)
