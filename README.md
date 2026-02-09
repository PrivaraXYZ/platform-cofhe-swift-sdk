# CoFHE Swift SDK

[![CI](https://github.com/PrivaraXYZ/platform-cofhe-swift-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/PrivaraXYZ/platform-cofhe-swift-sdk/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Swift SDK for [Privara CoFHE](https://github.com/PrivaraXYZ/platform-cofhe-nodejs-worker) — Fully Homomorphic Encryption (FHE) service powered by Fhenix CoFHE.

## Features

- **Type-safe API** — Compile-time validation for all FHE types
- **Native async/await** — All methods are `async throws`
- **Batch encryption** — Encrypt up to 10 values in a single request
- **Error handling** — RFC 7807 Problem Details with typed `CoFheError` enum
- **Health checks** — Liveness and readiness probes
- **Zero dependencies** — Pure URLSession, no third-party libraries

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/PrivaraXYZ/platform-cofhe-swift-sdk.git", from: "0.1.0")
]
```

Then add `CoFheSDK` to your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["CoFheSDK"]
)
```

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'CoFheSDK', '~> 0.1.0'
```

## Quick Start

```swift
import CoFheSDK

let client = CoFheClient(config: .init(baseURL: "https://cofhe.privara.xyz"))

// Encrypt a single value
let encrypted = try await client.encryptUint64(
    value: "1000000",
    userAddress: "0x1234567890123456789012345678901234567890"
)
print("Encrypted: \(encrypted.data)")
print("Proof: \(encrypted.inputProof)")

// Batch encryption
let batch = try await client.encryptBatch(
    userAddress: "0x1234567890123456789012345678901234567890",
    items: [
        .uint64("1000000"),
        .bool(true),
        .address("0xabcdef0123456789abcdef0123456789abcdef01")
    ]
)
print("Encrypted \(batch.results.count) values in \(batch.totalEncryptionTimeMs)ms")

client.close()
```

## API Reference

### Typed Endpoints

```swift
// 8-bit unsigned integer (0..255)
try await client.encryptUint8(value: Int, userAddress: String) -> EncryptedValue

// 16-bit unsigned integer (0..65535)
try await client.encryptUint16(value: Int, userAddress: String) -> EncryptedValue

// 32-bit unsigned integer (0..4294967295)
try await client.encryptUint32(value: UInt32, userAddress: String) -> EncryptedValue

// 64-bit unsigned integer (decimal string)
try await client.encryptUint64(value: String, userAddress: String) -> EncryptedValue

// 128-bit unsigned integer (decimal string)
try await client.encryptUint128(value: String, userAddress: String) -> EncryptedValue

// 256-bit unsigned integer (decimal string)
try await client.encryptUint256(value: String, userAddress: String) -> EncryptedValue

// Ethereum address (0x + 40 hex chars)
try await client.encryptAddress(value: String, userAddress: String) -> EncryptedValue

// Boolean
try await client.encryptBool(value: Bool, userAddress: String) -> EncryptedValue
```

### Generic Endpoint

```swift
try await client.encrypt(
    type: EncryptionType,
    value: Any,
    userAddress: String
) -> EncryptedValue
```

### Batch Encryption

```swift
try await client.encryptBatch(
    userAddress: String,
    items: [BatchItem]
) -> BatchEncryptResult

// Factory methods for BatchItem
BatchItem.uint8(Int)
BatchItem.uint16(Int)
BatchItem.uint32(UInt32)
BatchItem.uint64(String)      // decimal string
BatchItem.uint128(String)     // decimal string
BatchItem.uint256(String)     // decimal string
BatchItem.address(String)
BatchItem.bool(Bool)
```

### Health Checks

```swift
// Liveness probe (returns true if service is running)
await client.isAlive() -> Bool

// Readiness probe (returns true if FHE SDK is initialized)
await client.isReady() -> Bool

// Detailed readiness status
try await client.healthReady() -> HealthStatus
```

## Configuration

```swift
let client = CoFheClient(config: .init(
    baseURL: "https://cofhe.privara.xyz",
    requestTimeout: 120,       // default: 60 seconds
    connectTimeout: 10,        // default: 10 seconds
    enableLogging: true,       // default: false
    urlSession: customSession  // default: nil (SDK creates its own)
))
```

## Error Handling

All errors throw `CoFheError` enum with specific cases:

```swift
do {
    try await client.encryptUint64(value: "1000000", userAddress: address)
} catch let error as CoFheError {
    switch error {
    case .timeout(let message):
        // Retry
    case .notInitialized(let message):
        // Wait and retry
    case .validationFailed(let message, let invalidParams):
        // Check invalidParams
        invalidParams.forEach { print("\($0.name): \($0.reason)") }
    case .networkError(let message, let underlying):
        // Connection failed
    default:
        // HTTP status code available
        print("Error: \(error.message) (HTTP \(error.statusCode))")
    }
}
```

### Error Types

**Server errors:**
- `validationFailed` (400) — Request validation error with `invalidParams`
- `invalidAddress` (422) — Invalid Ethereum address format
- `invalidValue` (422) — Value out of range for type
- `unsupportedType` (422) — Unknown encryption type
- `encryptionFailed` (500) — FHE encryption operation failed
- `internalServerError` (500) — Generic server error
- `notInitialized` (503) — FHE SDK not initialized yet
- `initializationFailed` (503) — FHE SDK initialization failed
- `poolExhausted` (503) — Too many concurrent requests
- `timeout` (504) — Encryption timeout
- `unknownServerError` — Unknown URN from server

**Client errors:**
- `networkError` — Connection/DNS/TLS failure
- `serializationError` — JSON parsing failure

## Response Model

```swift
struct EncryptedValue {
    let type: EncryptionType       // .uint64, .bool, etc.
    let data: String               // hex ctHash for smart contract
    let securityZone: Int          // FHE security zone
    let utype: Int                 // FHE type identifier
    let inputProof: String         // hex ZK proof
    let encryptionTimeMs: Int64    // encryption duration
}
```

## Platform Support

- **iOS** 15+
- **macOS** 12+
- **tvOS** 15+
- **watchOS** 8+

## Testing

```bash
# Unit tests
swift test

# E2E tests (requires running CoFHE service)
COFHE_BASE_URL=https://... swift test --filter E2E
```

### Mock Testing

The SDK uses `URLProtocol` for unit testing:

```swift
MockURLProtocol.requestHandler = { request in
    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    return (response, jsonData)
}
let session = URLSession(configuration: MockURLProtocol.sessionConfiguration)
let client = CoFheClient(config: .init(baseURL: "http://test", urlSession: session))
```

## Development

```bash
# Build
swift build

# Run tests
swift test

# Generate Xcode project (optional)
swift package generate-xcodeproj
```

## License

MIT

## Links

- [CoFHE Worker Service](https://github.com/PrivaraXYZ/platform-cofhe-nodejs-worker)
- [Kotlin SDK](https://github.com/PrivaraXYZ/platform-cofhe-kotlin-sdk)
- [Fhenix CoFHE](https://docs.fhenix.io/)
- [API Documentation](https://cofhe.privara.xyz/api/docs)
