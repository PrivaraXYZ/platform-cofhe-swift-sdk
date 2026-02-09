import Foundation

/// Result of a batch encryption operation.
public struct BatchEncryptResult: Codable, Sendable {
    /// Individual encryption results.
    public let results: [EncryptedValue]
    /// Total encryption time in milliseconds.
    public let totalEncryptionTimeMs: Int64
}
