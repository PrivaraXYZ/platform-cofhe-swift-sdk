import Foundation

/// Configuration for ``CoFheClient``.
public struct CoFheClientConfig: Sendable {

    /// Base URL of the CoFHE service (without trailing slash).
    public let baseURL: String

    /// Maximum time to wait for a complete request (seconds). Default: 60.
    public let requestTimeout: TimeInterval

    /// Maximum time to establish a connection (seconds). Default: 10.
    public let connectTimeout: TimeInterval

    /// Enable HTTP request/response logging via `os.Logger`. Default: false.
    public let enableLogging: Bool

    /// Custom URLSession for testing or advanced configuration. Default: nil (SDK creates its own).
    public let urlSession: URLSession?

    /// Normalized base URL (trailing slashes removed).
    public var normalizedBaseURL: String {
        var url = baseURL
        while url.hasSuffix("/") {
            url = String(url.dropLast())
        }
        return url
    }

    /// Create a new configuration.
    ///
    /// - Parameters:
    ///   - baseURL: Base URL of the CoFHE service (required).
    ///   - requestTimeout: Maximum time for a complete request in seconds. Default: 60.
    ///   - connectTimeout: Maximum time to establish a connection in seconds. Default: 10.
    ///   - enableLogging: Enable HTTP logging. Default: false.
    ///   - urlSession: Custom URLSession. Default: nil.
    public init(
        baseURL: String,
        requestTimeout: TimeInterval = 60,
        connectTimeout: TimeInterval = 10,
        enableLogging: Bool = false,
        urlSession: URLSession? = nil
    ) {
        precondition(!baseURL.trimmingCharacters(in: .whitespaces).isEmpty, "baseURL must not be blank")
        self.baseURL = baseURL
        self.requestTimeout = requestTimeout
        self.connectTimeout = connectTimeout
        self.enableLogging = enableLogging
        self.urlSession = urlSession
    }
}
