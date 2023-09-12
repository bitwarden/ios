import XCTest

@testable import BitwardenShared

// MARK: - StringTests

class StringTests: BitwardenTestCase {
    // MARK: Tests

    func test_urlDecoded_withInvalidString() {
        let subject = "a_bc-"

        XCTAssertThrowsError(try subject.urlDecoded()) { error in
            XCTAssertEqual(error as? URLDecodingError, .invalidLength)
        }
    }

    func test_urlDecoded_withValidString() throws {
        let subject = "a_bcd-"
        let decoded = try subject.urlDecoded()

        XCTAssertEqual(decoded, "a/bcd+==")
    }

    func test_urlEncoded() {
        let subject = "a/bcd+=="
        let encoded = subject.urlEncoded()

        XCTAssertEqual(encoded, "a_bcd-")
    }
}
