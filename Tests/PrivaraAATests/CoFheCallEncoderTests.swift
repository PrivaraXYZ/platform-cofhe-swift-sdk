import XCTest
@testable import PrivaraAA

final class CoFheCallEncoderTests: XCTestCase {

    func testWordIsBigEndian32Bytes() {
        let w = CoFheCallEncoder.word(64)
        XCTAssertEqual(w.count, 32)
        XCTAssertEqual(w[31], 64)
        XCTAssertTrue(w[0..<31].allSatisfy { $0 == 0 })
    }

    func testHexDecodingStripsPrefix() throws {
        XCTAssertEqual(try CoFheCallEncoder.bytes(fromHex: "0xdeadbeef"), [0xde, 0xad, 0xbe, 0xef])
        XCTAssertEqual(try CoFheCallEncoder.bytes(fromHex: "DEADBEEF"), [0xde, 0xad, 0xbe, 0xef])
    }

    func testHexDecodingRejectsOddLength() {
        XCTAssertThrowsError(try CoFheCallEncoder.bytes(fromHex: "0xabc"))
    }

    func testSelectorMustBeFourBytes() {
        XCTAssertThrowsError(
            try CoFheCallEncoder.encode(
                selector: [1, 2, 3],
                ciphertextHashHex: String(repeating: "00", count: 32),
                inputProofHex: "00"
            )
        )
    }

    func testCiphertextHashMustBe32Bytes() {
        XCTAssertThrowsError(
            try CoFheCallEncoder.encode(
                selector: [1, 2, 3, 4],
                ciphertextHashHex: String(repeating: "00", count: 31),
                inputProofHex: "00"
            )
        )
    }

    func testEncodeLayout() throws {
        let selector: [UInt8] = [0xa9, 0x05, 0x9c, 0xbb]
        let ctHash = String(repeating: "11", count: 32)
        let proof = "0x" + String(repeating: "22", count: 64) // 64 bytes (word-aligned)

        let out = try CoFheCallEncoder.encode(
            selector: selector,
            ciphertextHashHex: ctHash,
            inputProofHex: proof
        )

        // selector(4) + ctHash(32) + offset(32) + length(32) + proof(64)
        XCTAssertEqual(out.count, 4 + 32 + 32 + 32 + 64)
        XCTAssertEqual(Array(out[0..<4]), selector)
        XCTAssertEqual(Array(out[4..<36]), [UInt8](repeating: 0x11, count: 32))
        XCTAssertEqual(Array(out[36..<68]), CoFheCallEncoder.word(64))   // offset
        XCTAssertEqual(Array(out[68..<100]), CoFheCallEncoder.word(64))  // length
        XCTAssertEqual(Array(out[100..<164]), [UInt8](repeating: 0x22, count: 64))
    }

    func testEncodePadsProofToWordBoundary() throws {
        let out = try CoFheCallEncoder.encode(
            selector: [1, 2, 3, 4],
            ciphertextHashHex: String(repeating: "00", count: 32),
            inputProofHex: "aabbcc" // 3 bytes -> padded to one 32-byte word
        )
        XCTAssertEqual(out.count, 4 + 32 + 32 + 32 + 32)
        // Final word: 0xaabbcc00...0
        XCTAssertEqual(Array(out[100..<132]), [0xaa, 0xbb, 0xcc] + [UInt8](repeating: 0, count: 29))
    }
}
