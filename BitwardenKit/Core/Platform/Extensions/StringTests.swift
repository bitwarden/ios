import BitwardenKit
import XCTest

// MARK: - StringTests

class StringTests: BitwardenTestCase {
    // MARK: Tests

    /// `formattedCreditCardNumber()` formats valid credit card numbers with spaces every 4 digits.
    func test_formattedCreditCardNumber_withValidNumbers() {
        XCTAssertEqual("1234567890123456".formattedCreditCardNumber(), "1234 5678 9012 3456")
        XCTAssertEqual("4400123456789".formattedCreditCardNumber(), "4400 1234 5678 9")
        XCTAssertEqual("378282246310005".formattedCreditCardNumber(), "3782 8224 6310 005")
        XCTAssertEqual("4111111111111111".formattedCreditCardNumber(), "4111 1111 1111 1111")
        XCTAssertEqual("1234".formattedCreditCardNumber(), "1234")
        XCTAssertEqual("".formattedCreditCardNumber(), "")
    }

    /// `formattedCreditCardNumber()` handles already spaced numbers correctly.
    func test_formattedCreditCardNumber_withSpacedNumbers() {
        XCTAssertEqual("1234 5678 9012 3456".formattedCreditCardNumber(), "1234 5678 9012 3456")
        XCTAssertEqual("4400 1234 5678 9".formattedCreditCardNumber(), "4400 1234 5678 9")
        XCTAssertEqual("1234 5678".formattedCreditCardNumber(), "1234 5678")
    }

    /// `formattedCreditCardNumber()` returns original string for invalid input.
    func test_formattedCreditCardNumber_withInvalidInput() {
        XCTAssertEqual("1234-5678-9012-3456".formattedCreditCardNumber(), "1234-5678-9012-3456")
        XCTAssertEqual("abcd5678".formattedCreditCardNumber(), "abcd5678")
        XCTAssertEqual("1234 abcd".formattedCreditCardNumber(), "1234 abcd")
        XCTAssertEqual("hello world".formattedCreditCardNumber(), "hello world")
        XCTAssertEqual("4111-1111-1111-1111".formattedCreditCardNumber(), "4111-1111-1111-1111")
    }

    /// `hashColor` returns a color generated from a hash of the string's characters.
    func test_hashColor() {
        XCTAssertEqual("test".hashColor.description, "#924436FF")
        XCTAssertEqual("0620ee30-91c3-40cb-8fad-b102005c35b0".hashColor.description, "#32F23FFF")
        XCTAssertEqual("9c303aee-e636-4760-94b6-e4951d7b0abb".hashColor.description, "#C96CD2FF")
    }

    /// `hexSHA256Hash` returns a hexadecimal string with a SHA-256 hash of the string.
    func test_hexSHA256Hash() {
        let subject = "String to be hashed"
        let expected = "6bd36935ea986ded286b264a72f5e008cc4434082877e4b12c91511d3803b22f"

        XCTAssertEqual(subject.hexSHA256Hash, expected)
    }

    /// `httpsNormalized()` adds HTTPS prefix when no scheme is present.
    func test_httpsNormalized_addsHttpsPrefix() {
        XCTAssertEqual("example.com".httpsNormalized(), "https://example.com")
        XCTAssertEqual("bitwarden.com".httpsNormalized(), "https://bitwarden.com")
        XCTAssertEqual("sub.domain.example.com".httpsNormalized(), "https://sub.domain.example.com")
    }

    /// `httpsNormalized()` removes trailing slash.
    func test_httpsNormalized_removesTrailingSlash() {
        XCTAssertEqual("example.com/".httpsNormalized(), "https://example.com")
        XCTAssertEqual("https://example.com/".httpsNormalized(), "https://example.com")
        XCTAssertEqual("http://example.com/".httpsNormalized(), "http://example.com")
    }

    /// `httpsNormalized()` preserves existing HTTPS scheme.
    func test_httpsNormalized_preservesHttpsScheme() {
        XCTAssertEqual("https://example.com".httpsNormalized(), "https://example.com")
        XCTAssertEqual("https://bitwarden.com".httpsNormalized(), "https://bitwarden.com")
        XCTAssertEqual("https://example.com:8080".httpsNormalized(), "https://example.com:8080")
    }

    /// `httpsNormalized()` preserves existing HTTP scheme.
    func test_httpsNormalized_preservesHttpScheme() {
        XCTAssertEqual("http://example.com".httpsNormalized(), "http://example.com")
        XCTAssertEqual("http://bitwarden.com".httpsNormalized(), "http://bitwarden.com")
        XCTAssertEqual("http://localhost:8080".httpsNormalized(), "http://localhost:8080")
    }

    /// `httpsNormalized()` handles URLs with paths correctly.
    func test_httpsNormalized_withPaths() {
        XCTAssertEqual("example.com/path".httpsNormalized(), "https://example.com/path")
        XCTAssertEqual("https://example.com/path".httpsNormalized(), "https://example.com/path")
        XCTAssertEqual("example.com/path/to/resource".httpsNormalized(), "https://example.com/path/to/resource")
        XCTAssertEqual("https://example.com/path/".httpsNormalized(), "https://example.com/path")
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

    /// `whitespaceRemoved()` returns the string with whitespace removed.
    func test_whitespaceRemoved() {
        let subject = "  N  o  Whi te  Space   "
        let expected = "NoWhiteSpace"

        XCTAssertEqual(expected, subject.whitespaceRemoved())
    }

    /// `withoutAutomaticEmailLinks()` returns the string with email addresses appropriately modified.
    func test_withoutAutomaticEmailLinks() {
        let subject = "person@example.com"
        let modified = subject.withoutAutomaticEmailLinks()

        XCTAssertEqual(modified, "person\u{2060}@example.com")
    }
}
