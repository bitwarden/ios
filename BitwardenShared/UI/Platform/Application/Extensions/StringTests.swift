import XCTest

@testable import BitwardenShared

// MARK: - StringTests

class StringTests: BitwardenTestCase {
    // MARK: Tests

    /// `isValidEmail` with an invalid string returns `false`.
    func test_isValidEmail_withInvalidString() {
        let subjects = [
            "",
            "email",
            "email@example",
            "email@example.",
            "@example.com",
            "email@.com",
            "example.com",
            "example.com@email",
            "@@example.com",
            " @example.com",
            " email@example.com",
            "email@example.com ",
        ]

        // All strings should _not_ be considered valid emails
        XCTAssertTrue(subjects.allSatisfy { string in
            !string.isValidEmail
        })
    }

    /// `isValidEmail` with a valid string returns `true`.
    func test_isValidEmail_withValidString() {
        let subjects = [
            "email@example.com",
            "e@e.c",
        ]

        XCTAssertTrue(subjects.allSatisfy(\.isValidEmail))
    }

    /// `urlDecoded()` with an invalid string throws an error.
    func test_urlDecoded_withInvalidString() {
        let subject = "a_bc-"

        XCTAssertThrowsError(try subject.urlDecoded()) { error in
            XCTAssertEqual(error as? URLDecodingError, .invalidLength)
        }
    }

    /// `urlDecoded()` with a valid string returns the decoded string.
    func test_urlDecoded_withValidString() throws {
        let subject = "a_bcd-"
        let decoded = try subject.urlDecoded()

        XCTAssertEqual(decoded, "a/bcd+==")
    }

    /// `urlEncoded()` returns the encoded string.
    func test_urlEncoded() {
        let subject = "a/bcd+=="
        let encoded = subject.urlEncoded()

        XCTAssertEqual(encoded, "a_bcd-")
    }
}
