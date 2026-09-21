import Foundation
import ZeroDevAA

/// Configuration for a Privara smart account backed by the ZeroDev Omni SDK.
///
/// Mirrors ``CoFheClientConfig`` in spirit: a small, validated value type that
/// captures everything needed to stand up a Kernel smart account.
public struct ZeroDevAccountConfig: Sendable {

    /// ZeroDev project ID (from dashboard.zerodev.app).
    public let projectID: String

    /// Target chain ID (e.g. `11155111` for Sepolia, `1` for mainnet).
    public let chainID: UInt64

    /// Optional custom RPC URL. Empty uses the ZeroDev default for `chainID`.
    public let rpcURL: String

    /// Optional custom bundler URL. Empty uses the ZeroDev default.
    public let bundlerURL: String

    /// Gas price middleware. ZeroDev calls `zd_getUserOperationGasPrice`.
    public let gasMiddleware: GasMiddleware

    /// Paymaster middleware. `.zeroDev` sponsors gas; `.none` = user pays.
    public let paymasterMiddleware: PaymasterMiddleware

    /// Kernel implementation version. Only `.v3_3` is available today.
    public let kernelVersion: KernelVersion

    public init(
        projectID: String,
        chainID: UInt64,
        rpcURL: String = "",
        bundlerURL: String = "",
        gasMiddleware: GasMiddleware = .zeroDev,
        paymasterMiddleware: PaymasterMiddleware = .zeroDev,
        kernelVersion: KernelVersion = .v3_3
    ) {
        precondition(
            !projectID.trimmingCharacters(in: .whitespaces).isEmpty,
            "projectID must not be blank"
        )
        precondition(chainID != 0, "chainID must not be zero")
        self.projectID = projectID
        self.chainID = chainID
        self.rpcURL = rpcURL
        self.bundlerURL = bundlerURL
        self.gasMiddleware = gasMiddleware
        self.paymasterMiddleware = paymasterMiddleware
        self.kernelVersion = kernelVersion
    }
}
