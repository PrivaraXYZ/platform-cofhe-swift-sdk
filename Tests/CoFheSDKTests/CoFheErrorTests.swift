import XCTest
@testable import CoFheSDK

final class CoFheErrorTests: XCTestCase {

    func testShouldMapValidationError() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:validation",
            title: "Validation Failed",
            status: 400,
            detail: "Request validation failed",
            invalidParams: [InvalidParam(name: "value", reason: "value must be a non-empty string")]
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .validationFailed(_, let params) = error {
            XCTAssertEqual(error.statusCode, 400)
            XCTAssertEqual(params.count, 1)
            XCTAssertEqual(params[0].name, "value")
        } else {
            XCTFail("Expected validationFailed, got \(error)")
        }
    }

    func testShouldMapInvalidAddressError() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:invalid-address",
            title: "Invalid Address",
            status: 422,
            detail: "Invalid user address: 0xinvalid"
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .invalidAddress = error {
            XCTAssertEqual(error.statusCode, 422)
        } else {
            XCTFail("Expected invalidAddress, got \(error)")
        }
    }

    func testShouldMapInvalidValueError() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:invalid-value",
            title: "Invalid Value",
            status: 422,
            detail: "Invalid encryption value"
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .invalidValue = error {
            XCTAssertEqual(error.statusCode, 422)
        } else {
            XCTFail("Expected invalidValue, got \(error)")
        }
    }

    func testShouldMapUnsupportedTypeError() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:unsupported-type",
            title: "Unsupported Type",
            status: 422,
            detail: "Unsupported encryption type: efloat"
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .unsupportedType = error {} else {
            XCTFail("Expected unsupportedType, got \(error)")
        }
    }

    func testShouldMapEncryptionFailedError() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:encryption-failed",
            title: "Encryption Failed",
            status: 500,
            detail: "Failed to encrypt uint64"
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .encryptionFailed = error {
            XCTAssertEqual(error.statusCode, 500)
        } else {
            XCTFail("Expected encryptionFailed, got \(error)")
        }
    }

    func testShouldMapInternalError() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:internal",
            title: "Internal Server Error",
            status: 500,
            detail: "Unknown error"
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .internalServerError = error {} else {
            XCTFail("Expected internalServerError, got \(error)")
        }
    }

    func testShouldMapNotInitializedError() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:not-initialized",
            title: "Service Not Ready",
            status: 503,
            detail: "FHEVM not initialized"
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .notInitialized = error {
            XCTAssertEqual(error.statusCode, 503)
        } else {
            XCTFail("Expected notInitialized, got \(error)")
        }
    }

    func testShouldMapInitializationFailedError() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:initialization-failed",
            title: "Initialization Failed",
            status: 503,
            detail: "FHEVM initialization failed"
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .initializationFailed = error {} else {
            XCTFail("Expected initializationFailed, got \(error)")
        }
    }

    func testShouldMapPoolExhaustedError() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:pool-exhausted",
            title: "Service Overloaded",
            status: 503,
            detail: "Worker pool exhausted"
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .poolExhausted = error {} else {
            XCTFail("Expected poolExhausted, got \(error)")
        }
    }

    func testShouldMapTimeoutError() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:timeout",
            title: "Encryption Timeout",
            status: 504,
            detail: "Encryption timeout after 30000ms"
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .timeout = error {
            XCTAssertEqual(error.statusCode, 504)
        } else {
            XCTFail("Expected timeout, got \(error)")
        }
    }

    func testShouldMapUnknownURNToUnknownServerError() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:some-future-error",
            title: "Future Error",
            status: 418,
            detail: "Something new"
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .unknownServerError(_, let code) = error {
            XCTAssertEqual(code, 418)
        } else {
            XCTFail("Expected unknownServerError, got \(error)")
        }
    }

    func testShouldHandleValidationErrorWithNoInvalidParams() {
        let problem = ProblemDetail(
            type: "urn:fhe:error:validation",
            title: "Validation Failed",
            status: 400,
            detail: "Request validation failed",
            invalidParams: nil
        )
        let error = CoFheError.fromProblemDetail(problem)
        if case .validationFailed(_, let params) = error {
            XCTAssertTrue(params.isEmpty)
        } else {
            XCTFail("Expected validationFailed, got \(error)")
        }
    }

    func testMessagePropertyReturnsDetail() {
        let error = CoFheError.invalidAddress(message: "Invalid address format")
        XCTAssertEqual(error.message, "Invalid address format")
    }
}
