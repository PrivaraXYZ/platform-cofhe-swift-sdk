# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
