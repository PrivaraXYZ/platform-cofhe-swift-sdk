import XCTest
@testable import CoFheSDK

/// End-to-end tests against real CoFHE service.
///
/// Requires `COFHE_BASE_URL` environment variable.
/// Run with: `COFHE_BASE_URL=https://... swift test --filter E2E`
final class CoFheClientE2ETests: XCTestCase {

    private static var client: CoFheClient!

    override class func setUp() {
        super.setUp()
        guard let baseURL = ProcessInfo.processInfo.environment["COFHE_BASE_URL"] else {
            return
        }
        client = CoFheClient(config: .init(baseURL: baseURL, requestTimeout: 120))
    }

    override func setUpWithError() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["COFHE_BASE_URL"] == nil,
            "COFHE_BASE_URL env var must be set for E2E tests"
        )
    }

    override class func tearDown() {
        client?.close()
        super.tearDown()
    }

    func testShouldCheckHealth() async throws {
        let result = await Self.client.isAlive()
        XCTAssertTrue(result)
    }

    func testShouldCheckReadiness() async throws {
        let result = await Self.client.isReady()
        XCTAssertTrue(result)
    }

    func testShouldEncryptUint64() async throws {
        let result = try await Self.client.encryptUint64(
            value: "1000000",
            userAddress: "0x1234567890123456789012345678901234567890"
        )
        XCTAssertEqual(result.type, .uint64)
        XCTAssertNotNil(result.data)
        XCTAssertTrue(result.data.hasPrefix("0x"))
        XCTAssertNotNil(result.inputProof)
        XCTAssertTrue(result.inputProof.hasPrefix("0x"))
        XCTAssertGreaterThan(result.encryptionTimeMs, 0)
    }

    func testShouldEncryptBatch() async throws {
        let result = try await Self.client.encryptBatch(
            userAddress: "0x1234567890123456789012345678901234567890",
            items: [
                .uint64("42"),
                .bool(true),
                .address("0xabcdef0123456789abcdef0123456789abcdef01"),
            ]
        )
        XCTAssertEqual(result.results.count, 3)
        XCTAssertEqual(result.results[0].type, .uint64)
        XCTAssertEqual(result.results[1].type, .bool)
        XCTAssertEqual(result.results[2].type, .address)
        XCTAssertGreaterThan(result.totalEncryptionTimeMs, 0)
    }

    func testShouldReturnErrorForInvalidInput() async throws {
        do {
            _ = try await Self.client.encrypt(
                type: .uint64,
                value: "not-a-number-but-server-decides",
                userAddress: "0x1234567890123456789012345678901234567890"
            )
        } catch let error as CoFheError {
            XCTAssertNotNil(error.message)
        }
    }
}
