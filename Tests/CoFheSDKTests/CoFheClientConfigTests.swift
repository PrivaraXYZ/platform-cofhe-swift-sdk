import XCTest
@testable import CoFheSDK

final class CoFheClientConfigTests: XCTestCase {

    func testShouldCreateConfigWithDefaults() {
        let config = CoFheClientConfig(baseURL: "http://localhost:3000")
        XCTAssertEqual(config.normalizedBaseURL, "http://localhost:3000")
        XCTAssertEqual(config.requestTimeout, 60)
        XCTAssertEqual(config.connectTimeout, 10)
        XCTAssertEqual(config.enableLogging, false)
        XCTAssertNil(config.urlSession)
    }

    func testShouldStripTrailingSlashFromBaseURL() {
        let config = CoFheClientConfig(baseURL: "http://localhost:3000/")
        XCTAssertEqual(config.normalizedBaseURL, "http://localhost:3000")
    }

    func testShouldStripMultipleTrailingSlashes() {
        let config = CoFheClientConfig(baseURL: "http://localhost:3000///")
        XCTAssertEqual(config.normalizedBaseURL, "http://localhost:3000")
    }

    func testShouldAcceptCustomTimeouts() {
        let config = CoFheClientConfig(
            baseURL: "http://localhost:3000",
            requestTimeout: 120,
            connectTimeout: 5
        )
        XCTAssertEqual(config.requestTimeout, 120)
        XCTAssertEqual(config.connectTimeout, 5)
    }

    func testShouldAcceptCustomURLSession() {
        let session = URLSession(configuration: .ephemeral)
        let config = CoFheClientConfig(baseURL: "http://localhost:3000", urlSession: session)
        XCTAssertNotNil(config.urlSession)
    }

    func testShouldAcceptLoggingEnabled() {
        let config = CoFheClientConfig(baseURL: "http://localhost:3000", enableLogging: true)
        XCTAssertEqual(config.enableLogging, true)
    }
}
