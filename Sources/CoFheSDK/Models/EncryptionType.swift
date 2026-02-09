import Foundation

/// Supported FHE encryption types.
public enum EncryptionType: String, Codable, CaseIterable, Sendable {
    case uint8 = "euint8"
    case uint16 = "euint16"
    case uint32 = "euint32"
    case uint64 = "euint64"
    case uint128 = "euint128"
    case uint256 = "euint256"
    case address = "eaddress"
    case bool = "ebool"

    /// The wire name used in JSON (e.g. "euint64", "ebool").
    public var typeName: String { rawValue }
}
