import Foundation

enum Validation {

    private static let addressRegex = try! NSRegularExpression(pattern: "^0x[a-fA-F0-9]{40}$")

    // Precomputed max values as decimal strings for string-based comparison
    private static let maxValues: [Int: String] = [
        64: "18446744073709551615",
        128: "340282366920938463463374607431768211455",
        256: "115792089237316195423570985008687907853269984665640564039457584007913129639935",
    ]

    static func isValidAddress(_ address: String) -> Bool {
        let range = NSRange(address.startIndex..<address.endIndex, in: address)
        return addressRegex.firstMatch(in: address, range: range) != nil
    }

    static func requireValidAddress(_ address: String) throws {
        guard isValidAddress(address) else {
            throw CoFheError.invalidInput(
                message: "userAddress must be a valid Ethereum address (0x + 40 hex chars), got \(address)"
            )
        }
    }

    /// Validate that a decimal string represents a non-negative integer within the given bit width.
    ///
    /// Uses string-length comparison to avoid BigInteger dependencies.
    static func requireUintRange(value: String, bits: Int, label: String) throws {
        guard let maxStr = maxValues[bits] else {
            preconditionFailure("Unsupported bit width: \(bits)")
        }

        // Must be non-empty, all digits, no leading zeros (except "0" itself)
        guard !value.isEmpty else {
            throw CoFheError.invalidInput(message: "\(label) value must not be empty")
        }

        guard value.allSatisfy(\.isNumber) else {
            throw CoFheError.invalidInput(message: "\(label) value must be a non-negative decimal integer, got \(value)")
        }

        if value.count > 1 {
            guard !value.hasPrefix("0") else {
                throw CoFheError.invalidInput(message: "\(label) value must not have leading zeros, got \(value)")
            }
        }

        // Compare by length first, then lexicographically
        guard value.count < maxStr.count || (value.count == maxStr.count && value <= maxStr) else {
            throw CoFheError.invalidInput(message: "\(label) value must be in range 0..2^\(bits)-1, got \(value)")
        }
    }
}
