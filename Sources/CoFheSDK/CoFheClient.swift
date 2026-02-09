import Foundation

/// Client for CoFHE (Confidential FHE) encryption service.
///
/// Provides type-safe encryption methods for all supported FHE types:
/// - Unsigned integers: uint8, uint16, uint32, uint64, uint128, uint256
/// - Ethereum addresses
/// - Booleans
/// - Batch encryption (up to 10 items)
///
/// Example:
/// ```swift
/// let client = CoFheClient(config: .init(baseURL: "https://cofhe.privara.xyz"))
///
/// let encrypted = try await client.encryptUint64(
///     value: "1000000",
///     userAddress: "0x1234567890123456789012345678901234567890"
/// )
///
/// // Use encrypted.data and encrypted.inputProof in smart contract calls
/// client.close()
/// ```
///
/// All methods throw ``CoFheError`` on errors.
public final class CoFheClient: Sendable {

    private let httpClient: HTTPClient

    /// Create a client with the given configuration.
    public init(config: CoFheClientConfig) {
        self.httpClient = HTTPClient(
            baseURL: config.normalizedBaseURL,
            session: config.urlSession,
            enableLogging: config.enableLogging,
            requestTimeout: config.requestTimeout,
            connectTimeout: config.connectTimeout
        )
    }

    // MARK: - Typed endpoints

    /// Encrypt an 8-bit unsigned integer (0..255).
    public func encryptUint8(value: Int, userAddress: String) async throws -> EncryptedValue {
        precondition(value >= 0 && value <= 255, "uint8 value must be in range 0..255, got \(value)")
        Validation.requireValidAddress(userAddress)
        return try await httpClient.post(path: ApiPaths.encryptUint8, body: TypedRequest(value: value, userAddress: userAddress))
    }

    /// Encrypt a 16-bit unsigned integer (0..65535).
    public func encryptUint16(value: Int, userAddress: String) async throws -> EncryptedValue {
        precondition(value >= 0 && value <= 65535, "uint16 value must be in range 0..65535, got \(value)")
        Validation.requireValidAddress(userAddress)
        return try await httpClient.post(path: ApiPaths.encryptUint16, body: TypedRequest(value: value, userAddress: userAddress))
    }

    /// Encrypt a 32-bit unsigned integer (0..4294967295).
    public func encryptUint32(value: UInt32, userAddress: String) async throws -> EncryptedValue {
        Validation.requireValidAddress(userAddress)
        return try await httpClient.post(path: ApiPaths.encryptUint32, body: TypedRequest(value: String(value), userAddress: userAddress))
    }

    /// Encrypt a 64-bit unsigned integer. Value is a decimal string (0..2^64-1).
    public func encryptUint64(value: String, userAddress: String) async throws -> EncryptedValue {
        Validation.requireUintRange(value: value, bits: 64, label: "uint64")
        Validation.requireValidAddress(userAddress)
        return try await httpClient.post(path: ApiPaths.encryptUint64, body: TypedRequest(value: value, userAddress: userAddress))
    }

    /// Encrypt a 128-bit unsigned integer. Value is a decimal string (0..2^128-1).
    public func encryptUint128(value: String, userAddress: String) async throws -> EncryptedValue {
        Validation.requireUintRange(value: value, bits: 128, label: "uint128")
        Validation.requireValidAddress(userAddress)
        return try await httpClient.post(path: ApiPaths.encryptUint128, body: TypedRequest(value: value, userAddress: userAddress))
    }

    /// Encrypt a 256-bit unsigned integer. Value is a decimal string (0..2^256-1).
    public func encryptUint256(value: String, userAddress: String) async throws -> EncryptedValue {
        Validation.requireUintRange(value: value, bits: 256, label: "uint256")
        Validation.requireValidAddress(userAddress)
        return try await httpClient.post(path: ApiPaths.encryptUint256, body: TypedRequest(value: value, userAddress: userAddress))
    }

    /// Encrypt an Ethereum address (0x + 40 hex characters).
    public func encryptAddress(value: String, userAddress: String) async throws -> EncryptedValue {
        precondition(
            Validation.isValidAddress(value),
            "address must match 0x followed by 40 hex characters, got \(value)"
        )
        Validation.requireValidAddress(userAddress)
        return try await httpClient.post(path: ApiPaths.encryptAddress, body: TypedRequest(value: value, userAddress: userAddress))
    }

    /// Encrypt a boolean value.
    public func encryptBool(value: Bool, userAddress: String) async throws -> EncryptedValue {
        Validation.requireValidAddress(userAddress)
        return try await httpClient.post(path: ApiPaths.encryptBool, body: TypedRequest(value: value, userAddress: userAddress))
    }

    // MARK: - Generic endpoint

    /// Encrypt a value of the given type.
    ///
    /// The value type must match the encryption type:
    /// - `.bool`: `Bool`
    /// - `.uint8`, `.uint16`: `Int`
    /// - `.uint32`: `UInt32` or `String`
    /// - `.uint64`, `.uint128`, `.uint256`: `String` (decimal)
    /// - `.address`: `String` (0x + 40 hex)
    public func encrypt(type: EncryptionType, value: Any, userAddress: String) async throws -> EncryptedValue {
        Validation.requireValidAddress(userAddress)
        let encodableValue = toEncodableValue(type: type, value: value)
        return try await httpClient.post(
            path: ApiPaths.encrypt,
            body: GenericRequest(type: type, value: encodableValue, userAddress: userAddress)
        )
    }

    // MARK: - Batch endpoint

    /// Encrypt multiple values in a single request (1..10 items).
    public func encryptBatch(userAddress: String, items: [BatchItem]) async throws -> BatchEncryptResult {
        precondition(!items.isEmpty, "batch items must not be empty")
        precondition(items.count <= 10, "batch items must not exceed 10, got \(items.count)")
        Validation.requireValidAddress(userAddress)

        let batchItems = items.map { item in
            BatchRequestItem(type: item.type, value: item.value)
        }
        return try await httpClient.post(
            path: ApiPaths.encryptBatch,
            body: BatchRequest(userAddress: userAddress, items: batchItems)
        )
    }

    // MARK: - Health endpoints

    /// Liveness probe. Returns `true` if the service is running.
    public func isAlive() async -> Bool {
        do {
            let statusCode = try await httpClient.getStatusCode(path: ApiPaths.health)
            return (200..<300).contains(statusCode)
        } catch {
            return false
        }
    }

    /// Readiness probe. Returns `true` if the FHE SDK is initialized and ready.
    public func isReady() async -> Bool {
        do {
            let status: HealthStatus = try await healthReady()
            return status.isHealthy
        } catch {
            return false
        }
    }

    /// Detailed readiness status.
    public func healthReady() async throws -> HealthStatus {
        return try await httpClient.get(path: ApiPaths.healthReady)
    }

    // MARK: - Lifecycle

    /// Close the client and release resources.
    ///
    /// Only invalidates the URLSession if it was created by the SDK.
    public func close() {
        httpClient.close()
    }

    // MARK: - Private request types

    private struct TypedRequest<T: Encodable>: Encodable {
        let value: T
        let userAddress: String
    }

    private struct GenericRequest: Encodable {
        let type: EncryptionType
        let value: AnyEncodable
        let userAddress: String
    }

    private struct BatchRequestItem: Encodable {
        let type: EncryptionType
        let value: AnyEncodable
    }

    private struct BatchRequest: Encodable {
        let userAddress: String
        let items: [BatchRequestItem]
    }

    // MARK: - Private helpers

    private func toEncodableValue(type: EncryptionType, value: Any) -> AnyEncodable {
        switch type {
        case .bool:
            return AnyEncodable(value as! Bool)
        case .uint8, .uint16:
            if let intVal = value as? Int {
                return AnyEncodable(intVal)
            }
            return AnyEncodable(String(describing: value))
        case .address:
            return AnyEncodable(value as! String)
        default:
            if let strVal = value as? String {
                return AnyEncodable(strVal)
            }
            return AnyEncodable(String(describing: value))
        }
    }
}
