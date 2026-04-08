import BitwardenKit
import XCTest

class BitwardenErrorTests: BitwardenTestCase {
    /// `dataError(_:)` returns an `NSError` with the correct domain, code, and user info.
    func test_dataError() {
        let error = BitwardenError.dataError("Something went wrong")

        XCTAssertEqual(error.domain, "Data Error")
        XCTAssertEqual(error.code, 3000)
        XCTAssertEqual(error.userInfo["ErrorMessage"] as? String, "Something went wrong")
    }

    /// `generalError(type:message:error:)` returns an `NSError` with the correct domain, code,
    /// and user info when no underlying error is provided.
    func test_generalError_noUnderlyingError() {
        let error = BitwardenError.generalError(type: "TestType", message: "A general error occurred")

        XCTAssertEqual(error.domain, "General Error: TestType")
        XCTAssertEqual(error.code, 4000)
        XCTAssertEqual(error.userInfo["ErrorMessage"] as? String, "A general error occurred")
        XCTAssertNil(error.userInfo[NSUnderlyingErrorKey])
    }

    /// `generalError(type:message:error:)` returns an `NSError` that includes the underlying error
    /// when one is provided.
    func test_generalError_withUnderlyingError() {
        let underlying = NSError(domain: "Underlying", code: 42)
        let error = BitwardenError.generalError(
            type: "TestType",
            message: "A general error occurred",
            error: underlying,
        )

        XCTAssertEqual(error.domain, "General Error: TestType")
        XCTAssertEqual(error.code, 4000)
        XCTAssertEqual(error.userInfo["ErrorMessage"] as? String, "A general error occurred")
        let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError
        XCTAssertEqual(underlyingError, underlying)
    }

    /// `generatorOptionsError(error:)` returns an `NSError` with the correct domain, code, and
    /// underlying error.
    func test_generatorOptionsError() {
        let underlying = NSError(domain: "Underlying", code: 99)
        let error = BitwardenError.generatorOptionsError(error: underlying)

        XCTAssertEqual(error.domain, "Generator Options Persisting Error")
        XCTAssertEqual(error.code, 2000)
        let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError
        XCTAssertEqual(underlyingError, underlying)
    }

    /// `logoutError(error:)` returns an `NSError` with the correct domain, code, and underlying
    /// error.
    func test_logoutError() {
        let underlying = NSError(domain: "Underlying", code: 7)
        let error = BitwardenError.logoutError(error: underlying)

        XCTAssertEqual(error.domain, "Logout Error")
        XCTAssertEqual(error.code, 1000)
        let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError
        XCTAssertEqual(underlyingError, underlying)
    }
}
