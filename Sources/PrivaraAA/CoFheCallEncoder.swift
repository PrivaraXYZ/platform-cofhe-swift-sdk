import Foundation

/// Errors thrown by ``CoFheCallEncoder``.
public enum CoFheCallEncoderError: Error, Equatable {
    case invalidSelector(count: Int)
    case invalidCiphertextHash(count: Int)
    case oddLengthHex(length: Int)
    case invalidHexCharacter(String)
}

/// Minimal, dependency-free ABI encoder for CoFHE contract calls.
///
/// CoFHE contract functions that accept an encrypted argument take a
/// `bytes32` ciphertext hash plus a dynamically-sized `bytes` input proof:
///
/// ```solidity
/// function someFn(bytes32 ctHash, bytes calldata inputProof) external;
/// ```
///
/// This type encodes the argument region for that signature. The caller
/// supplies the 4-byte function selector; everything after it is produced
/// here. It intentionally avoids pulling in a web3/ABI library so the SDK
/// keeps its zero-dependency posture.
public enum CoFheCallEncoder {

    /// ABI-encode `selector || (bytes32 ctHash, bytes inputProof)`.
    ///
    /// - Parameters:
    ///   - selector: 4-byte function selector (leading `0x` not required).
    ///   - ciphertextHashHex: 32-byte ciphertext hash, hex (optional `0x`).
    ///   - inputProofHex: variable-length input proof, hex (optional `0x`).
    public static func encode(
        selector: [UInt8],
        ciphertextHashHex: String,
        inputProofHex: String
    ) throws -> [UInt8] {
        guard selector.count == 4 else {
            throw CoFheCallEncoderError.invalidSelector(count: selector.count)
        }

        let ctHash = try bytes(fromHex: ciphertextHashHex)
        guard ctHash.count == 32 else {
            throw CoFheCallEncoderError.invalidCiphertextHash(count: ctHash.count)
        }

        let proof = try bytes(fromHex: inputProofHex)

        var out = selector
        out += ctHash                        // head word 0: bytes32 ciphertext hash
        out += word(UInt64(64))              // head word 1: offset of proof tail
        out += word(UInt64(proof.count))     // tail: length prefix
        out += proof                         // tail: proof data

        let padding = (32 - (proof.count % 32)) % 32
        if padding > 0 {
            out += [UInt8](repeating: 0, count: padding)
        }
        return out
    }

    /// Big-endian 32-byte word from a `UInt64`.
    public static func word(_ value: UInt64) -> [UInt8] {
        var big = value.bigEndian
        var bytes = [UInt8](repeating: 0, count: 32)
        withUnsafeBytes(of: &big) { raw in
            for (i, b) in raw.enumerated() {
                bytes[24 + i] = b
            }
        }
        return bytes
    }

    /// Decode a hex string (optional `0x` prefix) into bytes.
    public static func bytes(fromHex hex: String) throws -> [UInt8] {
        var s = hex
        if s.hasPrefix("0x") || s.hasPrefix("0X") {
            s = String(s.dropFirst(2))
        }
        guard s.count % 2 == 0 else {
            throw CoFheCallEncoderError.oddLengthHex(length: s.count)
        }

        var result = [UInt8]()
        result.reserveCapacity(s.count / 2)

        var index = s.startIndex
        while index < s.endIndex {
            let next = s.index(index, offsetBy: 2)
            let pair = s[index..<next]
            guard let byte = UInt8(pair, radix: 16) else {
                throw CoFheCallEncoderError.invalidHexCharacter(String(pair))
            }
            result.append(byte)
            index = next
        }
        return result
    }
}
