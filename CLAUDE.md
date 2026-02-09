# CLAUDE.md

## Project Overview

CoFHE Swift SDK — Swift client for the CoFHE FHE encryption service (Fhenix CoFHE).
Port of [platform-cofhe-kotlin-sdk](https://github.com/PrivaraXYZ/platform-cofhe-kotlin-sdk).

## Commands

```bash
swift build        # Build
swift test         # Run unit tests
swift test --filter E2E  # E2E tests (requires COFHE_BASE_URL env)
```

## Architecture

```
Sources/CoFheSDK/
├── Models/          # EncryptionType, EncryptedValue, BatchItem, BatchEncryptResult, HealthStatus
├── Error/           # CoFheError (enum), ProblemDetail (internal)
├── Internal/        # ApiPaths, AnyEncodable, Validation, HTTPClient
├── CoFheClientConfig.swift
└── CoFheClient.swift

Tests/CoFheSDKTests/
├── Helpers/         # MockURLProtocol
├── E2E/             # E2E tests (COFHE_BASE_URL required)
├── CoFheClientTests.swift
├── CoFheClientConfigTests.swift
├── CoFheErrorTests.swift
└── EncryptionTypeTests.swift
```

## Key Conventions

- Zero external dependencies (URLSession only)
- All public methods are `async throws`
- Errors: `CoFheError` enum with associated values
- BigInteger values (uint64/128/256) are `String` (decimal), validated via string comparison
- `CoFheClient` is `Sendable` and `final class`
- `precondition` for client-side validation (like Kotlin's `require`)
- RFC 7807 Problem Details for server errors
