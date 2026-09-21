# PRI-11 / 11a (PRI-15) — ZeroDev Swift SDK: version, support status & migration path

**Author:** GitHub agent (`github-9632ba37`)
**Scope:** confirm the ZeroDev Swift SDK to target, its support status, and the
migration path for `PrivaraXYZ/platform-cofhe-swift-sdk`.

---

## 1. Decision (go / no-go)

**GO — conditional.** Adopt the native Swift binding of the **ZeroDev Omni SDK**
(package/product `ZeroDevAA`). It is a real, first-class Swift SDK (async/await,
`AsyncSignerProtocol`, URLSession transport, EIP-7702) — not an Objective-C or
JS bridge. The conditions are alpha maturity and the platform-floor bump.

**Pin:** `zerodev-omni-sdk` **`0.0.1-alpha.4`** (`from: "0.0.1-alpha.4"`).

## 2. Pinned facts

| Item | Value |
|------|-------|
| Package | [`zerodevapp/zerodev-omni-sdk`](https://github.com/zerodevapp/zerodev-omni-sdk) |
| Product / module | `ZeroDevAA` (import `ZeroDevAA`) |
| Language bindings | One Zig core -> C FFI -> Go, Rust, **Swift**, Kotlin, Python, C |
| Latest Swift tag | **`v0.0.1-alpha.4`** (Swift tags: alpha.1...alpha.4) |
| Distribution | SPM; root `Package.swift` at the tag declares a **remote** `binaryTarget` (xcframework) with url + checksum — no Zig toolchain for consumers |
| Min platforms | **iOS 16+ / macOS 13+** (no tvOS/watchOS slices) |
| `swift-tools-version` | **6.0** |
| Support status | **Alpha / pre-1.0**, actively developed — API instability |
| Kernel version | `KernelVersion.v3_3` (only value; `.v3_3` supports EIP-7702) |

### Relevant Swift API surface (from the SDK sources)

```swift
Context(projectID:rpcURL:bundlerURL:chainID:gasMiddleware:paymasterMiddleware:)
Context.newAccount(signer:version:index:address:)
Context.newAccount7702(signer:version:)
Signer.local(privateKey: [UInt8]) / .generate() / .rpc(url:address:) / .custom(_:) / .async(_:providesSignAuthorization:)
Account.sendUserOp(calls: [Call]) async throws -> Hash
Account.waitForUserOperationReceipt(useropHash:timeoutMs:pollIntervalMs:) async throws -> UserOperationReceipt
Account.getAddressAsync()  // async
Call(target: Address, value: [UInt8] /*32B*/, calldata: [UInt8])
Context.useURLSessionTransport()   // called automatically in Context.init
```

## 3. Breaking-change notes for the CoFHE Swift SDK

Adopting `ZeroDevAA` forces **package-wide** changes (SwiftPM `platforms:` are
package-level, not per-target):

1. **Platform floor:** iOS 15 -> **16**, macOS 12 -> **13**.
2. **tvOS/watchOS dropped** — the xcframework has no slices for them. This is a
   consumer-visible break for anyone on tvOS/watchOS.
3. **`swift-tools-version` 5.9 -> 6.0**.
4. **New binary dependency** (`libzerodev_aa` + `libsecp256k1` xcframework):
   the package is no longer "zero dependencies" as a whole (the `CoFheSDK`
   target itself stays clean); adds app-size + supply-chain surface.
5. **Alpha API risk** — `0.0.1-alpha.x` may change signatures before 1.0.

### Mitigation

Put the ZeroDev integration in a **separate `PrivaraAA` target** (this PR) so the
`CoFheSDK` target's source stays untouched. Consumers who only need FHE can
depend on `CoFheSDK` alone; apps that want account abstraction add `PrivaraAA`.
The platform floor still rises package-wide, so release the AA work as a minor
bump with a migration note (and consider a `0.1.x` maintenance line for iOS 15
consumers).

## 4. Migration path (outline)

1. Add the SPM dependency + `PrivaraAA` target to `Package.swift`; raise
   platforms/tools version. (this PR)
2. Wrap the ZeroDev lifecycle in `ZeroDevSmartAccount`; expose async `send` /
   `waitForReceipt`; support EIP-7702. (this PR)
3. Bridge CoFHE -> calls via `EncryptedCallBuilder` + `CoFheCallEncoder`. (this PR)
4. Wire `Signer.async(_:)` for the Privy/wallet-provider signer used on iOS.
   (needs the app's wallet abstraction — follow-up)
5. Add CI: matrix build on iOS/macOS, run `swift build` + `swift test`.
   (needs CI runner with Xcode 16)
6. Integration test against Sepolia with a ZeroDev project ID.
   (needs project ID + faucet)

## 5. PRI-17 / 11c — review checklist (signing, storage, recovery, tx, errors, deps, safeguards, fallback)

| # | Area | Status in this PR | Follow-up |
|---|------|-------------------|-----------|
| 1 | **Signing** | `Signer.local` / `.generate` / `.rpc` / `.custom` / `.async` all supported; EIP-7702 `signAuthorization` path documented. | Confirm the app uses `Signer.async` (Privy) and not a local key on device. |
| 2 | **Key storage** | Delegated to the signer backend (Privy/KMS/HSM). No private keys handled by `PrivaraAA`. | Document the chosen backend + never log key material. |
| 3 | **Recovery** | ZeroDev **modular validators** (recovery/session keys) are *not* wired here. | Add validator/session-key support in a follow-up if recovery is in scope. |
| 4 | **Tx construction** | `send(calls:)` builds+sends a UserOp; `CoFheCallEncoder` produces `(bytes32,bytes)` calldata. | Validate calldata against the deployed contract ABI (no ABI artifacts in-repo yet). |
| 5 | **Error handling** | ZeroDev throws `AAError`; our types propagate `throws`. | Map `AAError` into a Privara-typed error (mirrors `CoFheError`) for ergonomics. |
| 6 | **Dependencies** | Adds xcframework `zerodev-omni-sdk@0.0.1-alpha.4` (libzerodev_aa + libsecp256k1). | Pin by exact version; review checksum; track upstream alpha releases. |
| 7 | **Safeguards** | Config validated via `precondition`; `send` rejects empty call lists; `useURLSessionTransport()` enforced. | Add spend/allowlist guardrails in the app layer. |
| 8 | **Fallback** | If `ZeroDevAA` cannot be linked, the app can still use `CoFheSDK` alone (separate target). | Document the "AA unavailable -> software wallet" fallback explicitly. |

**Blockers filed as follow-ups:** (a) CI runner + Xcode 16 to actually run
`swift build`/`swift test`; (b) a ZeroDev project ID + Sepolia funds for an
E2E test; (c) the app-side wallet/signer abstraction (Privy) integration.

## 6. Open questions for the team

- Is device-held key material ever acceptable, or must all signing go through
  Privy/KMS? (drives signer choice)
- Are recovery / session keys in scope for this migration?
- Which chains must the AA layer support at launch?

---

*Sources: ZeroDev Omni SDK root + Swift manifests and Swift sources at tag
`v0.0.1-alpha.4`; official Swift example `zerodevapp/omni-sdk-swift-example`.*
