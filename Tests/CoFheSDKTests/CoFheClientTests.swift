import XCTest
@testable import CoFheSDK

final class CoFheClientTests: XCTestCase {

    private let validAddress = "0xabcdef0123456789abcdef0123456789abcdef01"

    private func encryptedValueJSON(type: String = "euint64", utype: Int = 5) -> Data {
        """
        {
            "type": "\(type)",
            "data": "0xdata123",
            "securityZone": 0,
            "utype": \(utype),
            "inputProof": "0xinputproof456",
            "encryptionTimeMs": 1000
        }
        """.data(using: .utf8)!
    }

    private let batchResponseJSON = """
        {
            "results": [
                {
                    "type": "euint64",
                    "data": "0xdata123",
                    "securityZone": 0,
                    "utype": 5,
                    "inputProof": "0xinputproof456",
                    "encryptionTimeMs": 1000
                },
                {
                    "type": "ebool",
                    "data": "0xdata456",
                    "securityZone": 0,
                    "utype": 13,
                    "inputProof": "0xinputproof789",
                    "encryptionTimeMs": 500
                }
            ],
            "totalEncryptionTimeMs": 1500
        }
        """.data(using: .utf8)!

    private func createClient(handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data?)) -> CoFheClient {
        MockURLProtocol.requestHandler = handler
        let session = URLSession(configuration: MockURLProtocol.sessionConfiguration)
        return CoFheClient(config: .init(baseURL: "http://localhost:3000", urlSession: session))
    }

    private func successHandler(path: String? = nil, body: Data) -> (URLRequest) throws -> (HTTPURLResponse, Data?) {
        return { request in
            if let path {
                XCTAssertEqual(request.url?.path, path)
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, body)
        }
    }

    // MARK: - Successful responses

    func testEncryptUint8ShouldReturnEncryptedValue() async throws {
        let client = createClient(handler: successHandler(path: "/api/v1/encrypt/uint8", body: encryptedValueJSON(type: "euint8", utype: 0)))
        let result = try await client.encryptUint8(value: 42, userAddress: validAddress)
        XCTAssertEqual(result.type, .uint8)
        XCTAssertEqual(result.data, "0xdata123")
        client.close()
    }

    func testEncryptUint16ShouldReturnEncryptedValue() async throws {
        let client = createClient(handler: successHandler(path: "/api/v1/encrypt/uint16", body: encryptedValueJSON(type: "euint16", utype: 1)))
        let result = try await client.encryptUint16(value: 1000, userAddress: validAddress)
        XCTAssertEqual(result.type, .uint16)
        client.close()
    }

    func testEncryptUint32ShouldReturnEncryptedValue() async throws {
        let client = createClient(handler: successHandler(path: "/api/v1/encrypt/uint32", body: encryptedValueJSON(type: "euint32", utype: 2)))
        let result = try await client.encryptUint32(value: 4294967295, userAddress: validAddress)
        XCTAssertEqual(result.type, .uint32)
        client.close()
    }

    func testEncryptUint64ShouldReturnEncryptedValue() async throws {
        let client = createClient(handler: successHandler(path: "/api/v1/encrypt/uint64", body: encryptedValueJSON()))
        let result = try await client.encryptUint64(value: "1000000", userAddress: validAddress)
        XCTAssertEqual(result.type, .uint64)
        XCTAssertEqual(result.data, "0xdata123")
        XCTAssertEqual(result.securityZone, 0)
        XCTAssertEqual(result.utype, 5)
        XCTAssertEqual(result.inputProof, "0xinputproof456")
        XCTAssertEqual(result.encryptionTimeMs, 1000)
        client.close()
    }

    func testEncryptUint128ShouldReturnEncryptedValue() async throws {
        let client = createClient(handler: successHandler(body: encryptedValueJSON(type: "euint128", utype: 6)))
        let result = try await client.encryptUint128(value: "340282366920938463463374607431768211455", userAddress: validAddress)
        XCTAssertEqual(result.type, .uint128)
        client.close()
    }

    func testEncryptUint256ShouldReturnEncryptedValue() async throws {
        let client = createClient(handler: successHandler(body: encryptedValueJSON(type: "euint256", utype: 8)))
        let result = try await client.encryptUint256(
            value: "115792089237316195423570985008687907853269984665640564039457584007913129639935",
            userAddress: validAddress
        )
        XCTAssertEqual(result.type, .uint256)
        client.close()
    }

    func testEncryptAddressShouldReturnEncryptedValue() async throws {
        let client = createClient(handler: successHandler(path: "/api/v1/encrypt/address", body: encryptedValueJSON(type: "eaddress", utype: 7)))
        let result = try await client.encryptAddress(value: validAddress, userAddress: validAddress)
        XCTAssertEqual(result.type, .address)
        client.close()
    }

    func testEncryptBoolShouldReturnEncryptedValue() async throws {
        let client = createClient(handler: { request in
            XCTAssertEqual(request.url?.path, "/api/v1/encrypt/bool")
            let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            XCTAssertEqual(body["value"] as? Bool, true)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, self.encryptedValueJSON(type: "ebool", utype: 13))
        })
        let result = try await client.encryptBool(value: true, userAddress: validAddress)
        XCTAssertEqual(result.type, .bool)
        client.close()
    }

    func testEncryptGenericShouldReturnEncryptedValue() async throws {
        let client = createClient(handler: successHandler(path: "/api/v1/encrypt", body: encryptedValueJSON()))
        let result = try await client.encrypt(type: .uint64, value: "1000000", userAddress: validAddress)
        XCTAssertEqual(result.type, .uint64)
        client.close()
    }

    func testEncryptBatchShouldReturnBatchResult() async throws {
        let client = createClient(handler: successHandler(path: "/api/v1/encrypt/batch", body: batchResponseJSON))
        let result = try await client.encryptBatch(
            userAddress: validAddress,
            items: [
                .uint64("1000000"),
                .bool(true),
            ]
        )
        XCTAssertEqual(result.results.count, 2)
        XCTAssertEqual(result.results[0].type, .uint64)
        XCTAssertEqual(result.results[1].type, .bool)
        XCTAssertEqual(result.totalEncryptionTimeMs, 1500)
        client.close()
    }

    // MARK: - Error mapping

    func testShouldMap400ValidationError() async throws {
        let errorJSON = """
            {
                "type": "urn:fhe:error:validation",
                "title": "Validation Failed",
                "status": 400,
                "detail": "Request validation failed",
                "instance": "/api/v1/encrypt",
                "invalidParams": [{"name": "value", "reason": "value is required"}]
            }
            """.data(using: .utf8)!

        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, errorJSON)
        })

        do {
            _ = try await client.encryptUint64(value: "1", userAddress: validAddress)
            XCTFail("Expected error")
        } catch let error as CoFheError {
            if case .validationFailed(_, let params) = error {
                XCTAssertEqual(params.count, 1)
            } else {
                XCTFail("Expected validationFailed, got \(error)")
            }
        }
        client.close()
    }

    func testShouldMap422InvalidAddressError() async throws {
        let errorJSON = """
            {
                "type": "urn:fhe:error:invalid-address",
                "title": "Invalid Address",
                "status": 422,
                "detail": "Invalid user address"
            }
            """.data(using: .utf8)!

        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 422, httpVersion: nil, headerFields: nil)!
            return (response, errorJSON)
        })

        do {
            _ = try await client.encryptUint64(value: "1", userAddress: validAddress)
            XCTFail("Expected error")
        } catch let error as CoFheError {
            if case .invalidAddress = error {
                XCTAssertEqual(error.statusCode, 422)
            } else {
                XCTFail("Expected invalidAddress, got \(error)")
            }
        }
        client.close()
    }

    func testShouldMap422InvalidValueError() async throws {
        let errorJSON = """
            {
                "type": "urn:fhe:error:invalid-value",
                "title": "Invalid Value",
                "status": 422,
                "detail": "Invalid encryption value"
            }
            """.data(using: .utf8)!

        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 422, httpVersion: nil, headerFields: nil)!
            return (response, errorJSON)
        })

        do {
            _ = try await client.encryptUint64(value: "1", userAddress: validAddress)
            XCTFail("Expected error")
        } catch let error as CoFheError {
            if case .invalidValue = error {} else {
                XCTFail("Expected invalidValue, got \(error)")
            }
        }
        client.close()
    }

    func testShouldMap500EncryptionFailedError() async throws {
        let errorJSON = """
            {
                "type": "urn:fhe:error:encryption-failed",
                "title": "Encryption Failed",
                "status": 500,
                "detail": "Failed to encrypt uint64"
            }
            """.data(using: .utf8)!

        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, errorJSON)
        })

        do {
            _ = try await client.encryptUint64(value: "1", userAddress: validAddress)
            XCTFail("Expected error")
        } catch let error as CoFheError {
            if case .encryptionFailed = error {} else {
                XCTFail("Expected encryptionFailed, got \(error)")
            }
        }
        client.close()
    }

    func testShouldMap503NotInitializedError() async throws {
        let errorJSON = """
            {
                "type": "urn:fhe:error:not-initialized",
                "title": "Service Not Ready",
                "status": 503,
                "detail": "FHEVM not initialized"
            }
            """.data(using: .utf8)!

        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!
            return (response, errorJSON)
        })

        do {
            _ = try await client.encryptUint64(value: "1", userAddress: validAddress)
            XCTFail("Expected error")
        } catch let error as CoFheError {
            if case .notInitialized = error {} else {
                XCTFail("Expected notInitialized, got \(error)")
            }
        }
        client.close()
    }

    func testShouldMap503PoolExhaustedError() async throws {
        let errorJSON = """
            {
                "type": "urn:fhe:error:pool-exhausted",
                "title": "Service Overloaded",
                "status": 503,
                "detail": "Worker pool exhausted"
            }
            """.data(using: .utf8)!

        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!
            return (response, errorJSON)
        })

        do {
            _ = try await client.encryptUint64(value: "1", userAddress: validAddress)
            XCTFail("Expected error")
        } catch let error as CoFheError {
            if case .poolExhausted = error {} else {
                XCTFail("Expected poolExhausted, got \(error)")
            }
        }
        client.close()
    }

    func testShouldMap504TimeoutError() async throws {
        let errorJSON = """
            {
                "type": "urn:fhe:error:timeout",
                "title": "Encryption Timeout",
                "status": 504,
                "detail": "Encryption timeout after 30000ms"
            }
            """.data(using: .utf8)!

        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 504, httpVersion: nil, headerFields: nil)!
            return (response, errorJSON)
        })

        do {
            _ = try await client.encryptUint64(value: "1", userAddress: validAddress)
            XCTFail("Expected error")
        } catch let error as CoFheError {
            if case .timeout = error {} else {
                XCTFail("Expected timeout, got \(error)")
            }
        }
        client.close()
    }

    func testShouldMap500InternalError() async throws {
        let errorJSON = """
            {
                "type": "urn:fhe:error:internal",
                "title": "Internal Server Error",
                "status": 500,
                "detail": "Unknown error"
            }
            """.data(using: .utf8)!

        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, errorJSON)
        })

        do {
            _ = try await client.encryptUint64(value: "1", userAddress: validAddress)
            XCTFail("Expected error")
        } catch let error as CoFheError {
            if case .internalServerError = error {} else {
                XCTFail("Expected internalServerError, got \(error)")
            }
        }
        client.close()
    }

    func testShouldMapUnknownURNToUnknownServerError() async throws {
        let errorJSON = """
            {
                "type": "urn:fhe:error:some-new-error",
                "title": "New Error",
                "status": 418,
                "detail": "Something unexpected"
            }
            """.data(using: .utf8)!

        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 418, httpVersion: nil, headerFields: nil)!
            return (response, errorJSON)
        })

        do {
            _ = try await client.encryptUint64(value: "1", userAddress: validAddress)
            XCTFail("Expected error")
        } catch let error as CoFheError {
            if case .unknownServerError = error {} else {
                XCTFail("Expected unknownServerError, got \(error)")
            }
        }
        client.close()
    }

    // MARK: - Edge cases

    func testShouldHandleNonJSONErrorBody() async throws {
        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: ["Content-Type": "text/plain"])!
            return (response, "Internal Server Error".data(using: .utf8)!)
        })

        do {
            _ = try await client.encryptUint64(value: "1", userAddress: validAddress)
            XCTFail("Expected error")
        } catch let error as CoFheError {
            if case .unknownServerError(let message, _) = error {
                XCTAssertTrue(message.contains("Internal Server Error"))
            } else {
                XCTFail("Expected unknownServerError, got \(error)")
            }
        }
        client.close()
    }

    func testShouldHandleEmptyErrorBody() async throws {
        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        })

        do {
            _ = try await client.encryptUint64(value: "1", userAddress: validAddress)
            XCTFail("Expected error")
        } catch let error as CoFheError {
            if case .unknownServerError(let message, _) = error {
                XCTAssertTrue(message.contains("No response body"))
            } else {
                XCTFail("Expected unknownServerError, got \(error)")
            }
        }
        client.close()
    }

    // MARK: - Health endpoints

    func testIsAliveShouldReturnTrueWhenHealthy() async {
        let client = createClient(handler: { request in
            XCTAssertEqual(request.url?.path, "/health")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, #"{"status":"ok"}"#.data(using: .utf8)!)
        })
        let result = await client.isAlive()
        XCTAssertTrue(result)
        client.close()
    }

    func testIsAliveShouldReturnFalseOnError() async {
        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        })
        let result = await client.isAlive()
        XCTAssertFalse(result)
        client.close()
    }

    func testIsReadyShouldReturnTrueWhenReady() async {
        let client = createClient(handler: { request in
            XCTAssertEqual(request.url?.path, "/health/ready")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, #"{"status":"ok","info":{"fhe":{"status":"up"}},"error":{},"details":{}}"#.data(using: .utf8)!)
        })
        let result = await client.isReady()
        XCTAssertTrue(result)
        client.close()
    }

    func testIsReadyShouldReturnFalseWhenNotReady() async {
        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, #"{"status":"error","info":{},"error":{"fhe":{"status":"down"}},"details":{}}"#.data(using: .utf8)!)
        })
        let result = await client.isReady()
        XCTAssertFalse(result)
        client.close()
    }

    func testHealthReadyShouldReturnHealthStatus() async throws {
        let client = createClient(handler: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, #"{"status":"ok","info":{},"error":{},"details":{}}"#.data(using: .utf8)!)
        })
        let status = try await client.healthReady()
        XCTAssertTrue(status.isHealthy)
        client.close()
    }

    // MARK: - Request body validation

    func testEncryptUint64ShouldSendCorrectRequestBody() async throws {
        let client = createClient(handler: { request in
            let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            XCTAssertEqual(body["value"] as? String, "1000000")
            XCTAssertEqual(body["userAddress"] as? String, self.validAddress)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, self.encryptedValueJSON())
        })
        _ = try await client.encryptUint64(value: "1000000", userAddress: validAddress)
        client.close()
    }

    func testEncryptBatchShouldSendCorrectRequestBody() async throws {
        let client = createClient(handler: { request in
            let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            XCTAssertEqual(body["userAddress"] as? String, self.validAddress)
            let items = body["items"] as? [[String: Any]]
            XCTAssertEqual(items?.count, 2)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, self.batchResponseJSON)
        })
        _ = try await client.encryptBatch(
            userAddress: validAddress,
            items: [
                .uint64("1000000"),
                .bool(true),
            ]
        )
        client.close()
    }
}
