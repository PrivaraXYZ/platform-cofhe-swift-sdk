# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `PrivaraAA` library target — Swift-native ERC-4337 smart accounts via the
  [ZeroDev Omni SDK](https://github.com/zerodevapp/zerodev-omni-sdk) (`ZeroDevAA`).
  - `ZeroDevAccountConfig` — project ID, chain ID, RPC/bundler URLs, gas +
    paymaster middleware, Kernel version.
  - `ZeroDevSmartAccount` — context/signer/account lifecycle, `send(calls:)`,
    `waitForReceipt(...)`, `sendAndWait(...)`, and EIP-7702 (`newAccount7702`) support.
  - `EncryptedCallBuilder` + `CoFheCallEncoder` — bridge CoFHE ciphertexts and
    input proofs into smart-account calls:
    `selector(bytes32 ctHash, bytes inputProof)`.

### Changed

- **BREAKING:** package minimum platforms raised to **iOS 16 / macOS 13** and
  `swift-tools-version` raised to **6.0** to match the ZeroDev Omni SDK.
  **tvOS and watchOS are no longer declared** (the ZeroDev xcframework ships
  iOS/macOS slices only).
- Added a binary (xcframework) dependency on `zerodev-omni-sdk` `0.0.1-alpha.4`;
  the `CoFheSDK` target itself remains dependency-free.

## [0.1.0] - 2025-02-09

### Added

- Type-safe encryption API for all FHE types (uint8, uint16, uint32, uint64, uint128, uint256, address, bool)
- Generic encryption endpoint with `EncryptionType` enum
- Batch encryption supporting up to 10 values in a single request
- Health check methods (liveness and readiness probes)
- RFC 7807 Problem Details error handling with typed `CoFheError` enum
- URLSession-based HTTP client with configurable timeouts and logging
- Zero external dependencies
- Swift Package Manager and CocoaPods distribution
- Platforms: iOS 15+, macOS 12+, tvOS 15+, watchOS 8+
- Comprehensive test suite: unit tests (MockURLProtocol) and E2E tests

[0.1.0]: https://github.com/PrivaraXYZ/platform-cofhe-swift-sdk/releases/tag/v0.1.0
