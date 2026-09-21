// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CoFheSDK",
    platforms: [
        // Raised from iOS 15 / macOS 12 to match the ZeroDev Omni SDK
        // (ZeroDevAA), which requires iOS 16 / macOS 13. tvOS/watchOS are
        // intentionally dropped: the ZeroDev xcframework ships iOS + macOS
        // slices only. See Docs/PRI-11-zerodev-swift-migration.md.
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "CoFheSDK",
            targets: ["CoFheSDK"]
        ),
        .library(
            name: "PrivaraAA",
            targets: ["PrivaraAA"]
        ),
    ],
    dependencies: [
        // Swift-native ERC-4337 smart accounts (Kernel v3.3, paymaster,
        // EIP-7702). Consumed as a pre-built xcframework via SPM — the
        // release tag declares a remote binaryTarget (url + checksum), so
        // no Zig toolchain is required for consumers.
        .package(
            url: "https://github.com/zerodevapp/zerodev-omni-sdk.git",
            from: "0.0.1-alpha.4"
        ),
    ],
    targets: [
        .target(
            name: "CoFheSDK"
        ),
        .target(
            name: "PrivaraAA",
            dependencies: [
                "CoFheSDK",
                .product(name: "ZeroDevAA", package: "zerodev-omni-sdk"),
            ]
        ),
        .testTarget(
            name: "CoFheSDKTests",
            dependencies: ["CoFheSDK"]
        ),
        .testTarget(
            name: "PrivaraAATests",
            dependencies: ["PrivaraAA"]
        ),
    ]
)
