import Foundation

/// Health status of the CoFHE service.
public struct HealthStatus: Codable, Sendable {
    /// Status string from the server (e.g. "ok" or "error").
    public let status: String

    /// Whether the service reports healthy status.
    public var isHealthy: Bool { status == "ok" }
}
