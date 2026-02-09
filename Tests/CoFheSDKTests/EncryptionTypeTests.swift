import XCTest
@testable import CoFheSDK

final class EncryptionTypeTests: XCTestCase {

    func testShouldEncodeToJSONString() throws {
        let encoder = JSONEncoder()
        XCTAssertEqual(String(data: try encoder.encode(EncryptionType.uint64), encoding: .utf8), "\"euint64\"")
        XCTAssertEqual(String(data: try encoder.encode(EncryptionType.bool), encoding: .utf8), "\"ebool\"")
        XCTAssertEqual(String(data: try encoder.encode(EncryptionType.address), encoding: .utf8), "\"eaddress\"")
    }

    func testShouldDecodeFromJSONString() throws {
        let decoder = JSONDecoder()
        XCTAssertEqual(try decoder.decode(EncryptionType.self, from: "\"euint8\"".data(using: .utf8)!), .uint8)
        XCTAssertEqual(try decoder.decode(EncryptionType.self, from: "\"euint256\"".data(using: .utf8)!), .uint256)
    }

    func testShouldHaveCorrectTypeName() {
        XCTAssertEqual(EncryptionType.uint8.typeName, "euint8")
        XCTAssertEqual(EncryptionType.uint16.typeName, "euint16")
        XCTAssertEqual(EncryptionType.uint32.typeName, "euint32")
        XCTAssertEqual(EncryptionType.uint64.typeName, "euint64")
        XCTAssertEqual(EncryptionType.uint128.typeName, "euint128")
        XCTAssertEqual(EncryptionType.uint256.typeName, "euint256")
        XCTAssertEqual(EncryptionType.address.typeName, "eaddress")
        XCTAssertEqual(EncryptionType.bool.typeName, "ebool")
    }

    func testShouldHave8Cases() {
        XCTAssertEqual(EncryptionType.allCases.count, 8)
    }
}
