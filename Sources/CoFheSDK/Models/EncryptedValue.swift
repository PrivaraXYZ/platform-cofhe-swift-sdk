import Foundation

/// Result of a single FHE encryption operation.
public struct EncryptedValue: Codable, Equatable, Sendable {
    /// The FHE encryption type.
    public let type: EncryptionType
    /// Hex-encoded ctHash for smart contract calls.
    public let data: String
    /// FHE security zone.
    public let securityZone: Int
    /// FHE type identifier.
    public let utype: Int
    /// Hex-encoded ZK input proof.
    public let inputProof: String
    /// Duration of the encryption in milliseconds.
    public let encryptionTimeMs: Int64
}
