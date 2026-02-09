import Foundation

/// Error type for all CoFHE SDK errors.
///
/// Server errors are mapped from RFC 7807 Problem Details responses.
/// Client errors represent local failures (network, serialization).
public enum CoFheError: Error, Sendable {

    /// Invalid parameter in a validation error.
    public struct InvalidParameterInfo: Sendable, Equatable {
        public let name: String
        public let reason: String
    }

    // MARK: - Server errors

    /// Request validation failed (HTTP 400).
    case validationFailed(message: String, invalidParams: [InvalidParameterInfo])
    /// Invalid Ethereum address format (HTTP 422).
    case invalidAddress(message: String)
    /// Value out of range for the encryption type (HTTP 422).
    case invalidValue(message: String)
    /// Unknown/unsupported encryption type (HTTP 422).
    case unsupportedType(message: String)
    /// FHE encryption operation failed (HTTP 500).
    case encryptionFailed(message: String)
    /// Generic server error (HTTP 500).
    case internalServerError(message: String)
    /// FHE SDK not initialized yet (HTTP 503).
    case notInitialized(message: String)
    /// FHE SDK initialization failed (HTTP 503).
    case initializationFailed(message: String)
    /// Too many concurrent requests (HTTP 503).
    case poolExhausted(message: String)
    /// Encryption timeout (HTTP 504).
    case timeout(message: String)
    /// Unknown server error URN.
    case unknownServerError(message: String, statusCode: Int)

    // MARK: - Client errors

    /// Connection/DNS/TLS failure.
    case networkError(message: String, underlyingError: Error)
    /// JSON parsing failure.
    case serializationError(message: String, underlyingError: Error)
    /// Invalid input parameter (client-side validation).
    case invalidInput(message: String)

    /// HTTP status code associated with this error (0 for client-side errors).
    public var statusCode: Int {
        switch self {
        case .validationFailed: return 400
        case .invalidAddress, .invalidValue, .unsupportedType: return 422
        case .encryptionFailed, .internalServerError: return 500
        case .notInitialized, .initializationFailed, .poolExhausted: return 503
        case .timeout: return 504
        case .unknownServerError(_, let code): return code
        case .networkError, .serializationError, .invalidInput: return 0
        }
    }

    /// Human-readable error message.
    public var message: String {
        switch self {
        case .validationFailed(let msg, _): return msg
        case .invalidAddress(let msg): return msg
        case .invalidValue(let msg): return msg
        case .unsupportedType(let msg): return msg
        case .encryptionFailed(let msg): return msg
        case .internalServerError(let msg): return msg
        case .notInitialized(let msg): return msg
        case .initializationFailed(let msg): return msg
        case .poolExhausted(let msg): return msg
        case .timeout(let msg): return msg
        case .unknownServerError(let msg, _): return msg
        case .networkError(let msg, _): return msg
        case .serializationError(let msg, _): return msg
        case .invalidInput(let msg): return msg
        }
    }

    /// Create a ``CoFheError`` from a ``ProblemDetail`` response.
    static func fromProblemDetail(_ problem: ProblemDetail) -> CoFheError {
        let detail = problem.detail
        switch problem.type {
        case "urn:fhe:error:validation":
            let params = problem.invalidParams?.map {
                InvalidParameterInfo(name: $0.name, reason: $0.reason)
            } ?? []
            return .validationFailed(message: detail, invalidParams: params)
        case "urn:fhe:error:invalid-address":
            return .invalidAddress(message: detail)
        case "urn:fhe:error:invalid-value":
            return .invalidValue(message: detail)
        case "urn:fhe:error:unsupported-type":
            return .unsupportedType(message: detail)
        case "urn:fhe:error:encryption-failed":
            return .encryptionFailed(message: detail)
        case "urn:fhe:error:internal":
            return .internalServerError(message: detail)
        case "urn:fhe:error:not-initialized":
            return .notInitialized(message: detail)
        case "urn:fhe:error:initialization-failed":
            return .initializationFailed(message: detail)
        case "urn:fhe:error:pool-exhausted":
            return .poolExhausted(message: detail)
        case "urn:fhe:error:timeout":
            return .timeout(message: detail)
        default:
            return .unknownServerError(message: detail, statusCode: problem.status)
        }
    }
}

extension CoFheError: LocalizedError {
    public var errorDescription: String? { message }
}
