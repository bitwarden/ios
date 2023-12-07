import XCTest

@testable import BitwardenShared

// MARK: - StringTests

class StringTests: BitwardenTestCase {
    // MARK: Tests

    /// `isValidEmail` with an invalid string returns `false`.
    func test_isValidEmail_withInvalidString() {
        let subjects = [
            "",
            "e",
            "email",
            "example.com",
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
            "email@example",
            "email@example.",
            "@example.com",
            "email@.com",
            "example.com@email",
            "@@example.com",
            " @example.com",
            " email@example.com",
            "email@example.com ",
        ]

        XCTAssertTrue(subjects.allSatisfy(\.isValidEmail))
    }

    /// `isValidURL` returns `true` for a valid URL.
    func test_isValidURL_withValidURL() {
        XCTAssertTrue("http://bitwarden.com".isValidURL)
        XCTAssertTrue("https://bitwarden.com".isValidURL)
        XCTAssertTrue("bitwarden.com".isValidURL)
    }

    /// `isValidURL` returns `true` for an invalid URL.
    func test_isValidURL_withInvalidURL() {
        XCTAssertFalse(" ".isValidURL)
        XCTAssertFalse("a b c".isValidURL)
        XCTAssertFalse("a<b>c".isValidURL)
        XCTAssertFalse("a[b]c".isValidURL)
    }

    /// `nilIfEmpty` returns the string if it's not empty or `nil` if it's empty.
    func test_nilIfEmpty() {
        XCTAssertEqual("abc".nilIfEmpty, "abc")
        XCTAssertEqual("asdf1234".nilIfEmpty, "asdf1234")

        XCTAssertNil("".nilIfEmpty)
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
