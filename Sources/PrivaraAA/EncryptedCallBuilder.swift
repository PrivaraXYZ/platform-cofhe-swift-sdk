import Foundation
import CoFheSDK
import ZeroDevAA

/// Bridges the CoFHE encryption client to ZeroDev smart-account calls.
///
/// Encrypts a value with ``CoFheSDK/CoFheClient`` and produces a ZeroDev
/// ``Call`` that invokes `selector(bytes32 ctHash, bytes inputProof)` on a
/// target contract. This is the seam that makes "confidential value in a
/// gasless, account-abstracted transaction" a single, typed call.
public struct EncryptedCallBuilder: Sendable {

    /// The CoFHE client used for encryption.
    public let cofhe: CoFheClient

    public init(cofhe: CoFheClient) {
        self.cofhe = cofhe
    }

    /// Build a ``Call`` from an already-encrypted value.
    public func buildCall(
        to contract: Address,
        selector: [UInt8],
        encrypted: EncryptedValue,
        value: [UInt8] = [UInt8](repeating: 0, count: 32)
    ) throws -> Call {
        let calldata = try CoFheCallEncoder.encode(
            selector: selector,
            ciphertextHashHex: encrypted.data,
            inputProofHex: encrypted.inputProof
        )
        return Call(target: contract, value: value, calldata: calldata)
    }

    /// Encrypt a `uint64` and build the corresponding contract call in one step.
    public func encryptedUint64Call(
        to contract: Address,
        selector: [UInt8],
        uint64 value: String,
        userAddress: String,
        callValue: [UInt8] = [UInt8](repeating: 0, count: 32)
    ) async throws -> Call {
        let encrypted = try await cofhe.encryptUint64(value: value, userAddress: userAddress)
        return try buildCall(to: contract, selector: selector, encrypted: encrypted, value: callValue)
    }
}
