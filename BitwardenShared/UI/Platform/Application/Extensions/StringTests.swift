import XCTest

@testable import BitwardenShared

// MARK: - StringTests

class StringTests: BitwardenTestCase {
    // MARK: Tests

    /// `hashColor` returns a color generated from a hash of the string's characters.
    func test_hashColor() {
        XCTAssertEqual("test".hashColor.description, "#924436FF")
        XCTAssertEqual("0620ee30-91c3-40cb-8fad-b102005c35b0".hashColor.description, "#32F23FFF")
        XCTAssertEqual("9c303aee-e636-4760-94b6-e4951d7b0abb".hashColor.description, "#C96CD2FF")
    }

    /// `isValidURL` returns `true` for a valid URL.
    func test_isBitwardenAppScheme() {
        XCTAssertTrue("bitwarden".isBitwardenAppScheme)
        XCTAssertFalse(" ".isBitwardenAppScheme)
        XCTAssertFalse("bitwarden://".isBitwardenAppScheme)
        XCTAssertFalse("a<b>c".isBitwardenAppScheme)
        XCTAssertFalse("a[b]c".isBitwardenAppScheme)
    }

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

    /// `leftPadding(toLength:withPad:)` returns a string padded to the specified length.
    func test_leftPadding() {
        XCTAssertEqual("".leftPadding(toLength: 2, withPad: "0"), "00")
        XCTAssertEqual("AB".leftPadding(toLength: 4, withPad: "0"), "00AB")
        XCTAssertEqual("ABCD".leftPadding(toLength: 4, withPad: "0"), "ABCD")
        XCTAssertEqual("ABCDEF".leftPadding(toLength: 4, withPad: "0"), "CDEF")
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
