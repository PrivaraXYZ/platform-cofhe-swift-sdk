import Foundation
import ZeroDevAA

/// A Swift-native ERC-4337 smart account built directly on the ZeroDev Omni SDK.
///
/// This type owns the ZeroDev `Context` -> `Signer` -> `Account` lifecycle so
/// callers never have to touch the C FFI handle graph. All I/O is `async`; the
/// underlying ZeroDev async wrappers dispatch to a background queue, so these
/// methods are safe to `await` from any actor.
///
/// The signer is supplied by the caller (local key, JSON-RPC, or a custom
/// `AsyncSignerProtocol` implementation such as Privy). No Objective-C or
/// bridge shims are used — the Omni SDK is consumed natively via SPM.
///
/// ```swift
/// let account = try ZeroDevSmartAccount(
///     config: .init(projectID: projectID, chainID: 11155111),
///     privateKey: pk              // 32 bytes
/// )
/// let hash = try await account.send(calls: [call])
/// let receipt = try await account.waitForReceipt(useropHash: hash)
/// ```
public final class ZeroDevSmartAccount: @unchecked Sendable {

    public let config: ZeroDevAccountConfig

    /// Whether this account uses EIP-7702 delegation (EOA *is* the account).
    public let usesEIP7702: Bool

    private let context: Context
    private let signer: Signer
    private let account: Account

    /// Create an account from a locally-held 32-byte private key.
    ///
    /// - Parameter eip7702: When `true`, the account address is the signer's
    ///   EOA and delegation is installed on the first UserOp (no CREATE2).
    public convenience init(
        config: ZeroDevAccountConfig,
        privateKey: [UInt8],
        eip7702: Bool = false
    ) throws {
        precondition(privateKey.count == 32, "privateKey must be 32 bytes")
        let signer = try Signer.local(privateKey: privateKey)
        try self.init(config: config, signer: signer, eip7702: eip7702)
    }

    /// Create an account from a caller-provided signer.
    ///
    /// Use `Signer.async(_:)` to wrap an async wallet provider, or
    /// `Signer.custom(_:)` for an HSM/MPC backend.
    public init(
        config: ZeroDevAccountConfig,
        signer: Signer,
        eip7702: Bool = false
    ) throws {
        let context = try Context(
            projectID: config.projectID,
            rpcURL: config.rpcURL,
            bundlerURL: config.bundlerURL,
            chainID: config.chainID,
            gasMiddleware: config.gasMiddleware,
            paymasterMiddleware: config.paymasterMiddleware
        )

        // Context.init already routes HTTP through URLSession on Apple
        // platforms; keep an explicit call for clarity and forward-compat.
        context.useURLSessionTransport()

        self.config = config
        self.context = context
        self.signer = signer
        self.usesEIP7702 = eip7702

        if eip7702 {
            self.account = try context.newAccount7702(signer: signer, version: config.kernelVersion)
        } else {
            self.account = try context.newAccount(signer: signer, version: config.kernelVersion)
        }
    }

    /// The account's on-chain address.
    public func address() async throws -> Address {
        try await account.getAddressAsync()
    }

    /// Send one or more calls as a single UserOperation.
    @discardableResult
    public func send(calls: [Call]) async throws -> Hash {
        precondition(!calls.isEmpty, "calls must not be empty")
        return try await account.sendUserOp(calls: calls)
    }

    /// Poll until the UserOperation receipt is available.
    ///
    /// - Parameters:
    ///   - timeoutMs: `0` uses the SDK default.
    ///   - pollIntervalMs: `0` uses the SDK default.
    public func waitForReceipt(
        useropHash: Hash,
        timeoutMs: UInt32 = 0,
        pollIntervalMs: UInt32 = 0
    ) async throws -> UserOperationReceipt {
        try await account.waitForUserOperationReceipt(
            useropHash: useropHash,
            timeoutMs: timeoutMs,
            pollIntervalMs: pollIntervalMs
        )
    }

    /// Convenience: send then wait, returning the receipt.
    @discardableResult
    public func sendAndWait(
        calls: [Call],
        timeoutMs: UInt32 = 0,
        pollIntervalMs: UInt32 = 0
    ) async throws -> UserOperationReceipt {
        let hash = try await send(calls: calls)
        return try await waitForReceipt(
            useropHash: hash,
            timeoutMs: timeoutMs,
            pollIntervalMs: pollIntervalMs
        )
    }
}
