import Foundation

/// A single item in a batch encryption request.
///
/// Use static factory methods to create instances with compile-time type safety
/// and automatic validation.
///
/// ```swift
/// let items = [
///     BatchItem.uint64("1000000"),
///     BatchItem.bool(true),
///     BatchItem.address("0x1234...")
/// ]
/// ```
public struct BatchItem: Sendable {
    /// The FHE encryption type for this item.
    public let type: EncryptionType
    /// The value to encrypt (type-erased).
    internal let value: AnyEncodable

    private init(type: EncryptionType, value: AnyEncodable) {
        self.type = type
        self.value = value
    }

    /// Create a uint8 batch item (0..255).
    public static func uint8(_ value: Int) -> BatchItem {
        precondition(value >= 0 && value <= 255, "uint8 value must be in range 0..255, got \(value)")
        return BatchItem(type: .uint8, value: AnyEncodable(value))
    }

    /// Create a uint16 batch item (0..65535).
    public static func uint16(_ value: Int) -> BatchItem {
        precondition(value >= 0 && value <= 65535, "uint16 value must be in range 0..65535, got \(value)")
        return BatchItem(type: .uint16, value: AnyEncodable(value))
    }

    /// Create a uint32 batch item (0..4294967295).
    public static func uint32(_ value: UInt32) -> BatchItem {
        return BatchItem(type: .uint32, value: AnyEncodable(String(value)))
    }

    /// Create a uint64 batch item. Value is a decimal string (0..2^64-1).
    public static func uint64(_ value: String) -> BatchItem {
        Validation.requireUintRange(value: value, bits: 64, label: "uint64")
        return BatchItem(type: .uint64, value: AnyEncodable(value))
    }

    /// Create a uint128 batch item. Value is a decimal string (0..2^128-1).
    public static func uint128(_ value: String) -> BatchItem {
        Validation.requireUintRange(value: value, bits: 128, label: "uint128")
        return BatchItem(type: .uint128, value: AnyEncodable(value))
    }

    /// Create a uint256 batch item. Value is a decimal string (0..2^256-1).
    public static func uint256(_ value: String) -> BatchItem {
        Validation.requireUintRange(value: value, bits: 256, label: "uint256")
        return BatchItem(type: .uint256, value: AnyEncodable(value))
    }

    /// Create an address batch item (0x + 40 hex characters).
    public static func address(_ value: String) -> BatchItem {
        precondition(
            Validation.isValidAddress(value),
            "address must match 0x followed by 40 hex characters, got \(value)"
        )
        return BatchItem(type: .address, value: AnyEncodable(value))
    }

    /// Create a bool batch item.
    public static func bool(_ value: Bool) -> BatchItem {
        return BatchItem(type: .bool, value: AnyEncodable(value))
    }
}
