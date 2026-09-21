# PrivaraAA

Swift-native ERC-4337 smart accounts for Privara, built on the
[ZeroDev Omni SDK](https://github.com/zerodevapp/zerodev-omni-sdk) (`ZeroDevAA`),
with first-class bridging to `CoFheSDK` confidential encryption.

> Status: **scaffold** — introduced for PRI-11 (see
> `Docs/PRI-11-zerodev-swift-migration.md`). Pinned to `zerodev-omni-sdk`
> `0.0.1-alpha.4` (alpha API; expect churn before 1.0).

## Quick start

```swift
import PrivaraAA

// 1. Smart account (gasless Kernel v3.3 via ZeroDev paymaster)
let account = try ZeroDevSmartAccount(
    config: .init(projectID: "<zerodev-project-id>", chainID: 11155111),
    privateKey: secretKey32Bytes
)

// 2. Encrypt a value with CoFHE and turn it into a call
let cofhe = CoFheClient(config: .init(baseURL: "https://cofhe.privara.xyz"))
let builder = EncryptedCallBuilder(cofhe: cofhe)

let call = try await builder.encryptedUint64Call(
    to: try Address(hex: contractAddress),
    selector: [0xa9, 0x05, 0x9c, 0xbb],   // someFn(bytes32,bytes)
    uint64: "1000000",
    userAddress: "0x..."
)

// 3. Send as one UserOperation
let receipt = try await account.sendAndWait(calls: [call])
print(receipt.transactionHash)
```

## What's here

| Type | Purpose |
|------|---------|
| `ZeroDevAccountConfig` | Validated config (project/chain/RPC/bundler/middleware/kernel). |
| `ZeroDevSmartAccount` | Owns the ZeroDev `Context`/`Signer`/`Account` lifecycle; async `send`/`waitForReceipt`; EIP-7702 via `newAccount7702`. |
| `EncryptedCallBuilder` | Encrypts via `CoFheClient` and builds a ZeroDev `Call`. |
| `CoFheCallEncoder` | Dependency-free ABI encoder for `(bytes32 ctHash, bytes inputProof)`. |

## Signers

- Local key: `ZeroDevSmartAccount(config:privateKey:)`
- Async wallet provider (Privy, WalletConnect):
  `ZeroDevSmartAccount(config:signer: Signer.async(myProvider))`
- HSM/MPC: `Signer.custom(mySignerImpl)`

## Platform

iOS 16+ / macOS 13+. The ZeroDev xcframework does not ship tvOS/watchOS
slices, so those platforms are no longer declared by the package.
