import XCTest

@testable import BitwardenShared

class OptionalTests: BitwardenTestCase {
    // MARK: Tests

    /// `isEmptyOrNil` returns `true` if the wrapped collection is empty.
    func test_isEmptyOrNil_empty() {
        let subject: [String]? = []
        XCTAssertTrue(subject.isEmptyOrNil)
    }

    /// `isEmptyOrNil` returns `true` if the value is `nil`.
    func test_isEmptyOrNil_nil() {
        let subject: [String]? = nil
        XCTAssertTrue(subject.isEmptyOrNil)
    }

    /// `isEmptyOrNil` returns `false` if the wrapped collection is not empty.
    func test_isEmptyOrNil_notEmpty() {
        let subject: [String]? = ["a", "b", "c"]
        XCTAssertFalse(subject.isEmptyOrNil)
    }

    // MARK: Tests for Optional<String>

    /// `isWhitespaceOrNil` returns `false` if the string is not empty.
    func test_isWhitespaceOrNil_notEmpty() {
        let subject: String? = "something"
        XCTAssertFalse(subject.isWhitespaceOrNil)
    }

    /// `isWhitespaceOrNil` returns `true` if the string `nil`.
    func test_isWhitespaceOrNil_nil() {
        let subject: String? = nil
        XCTAssertTrue(subject.isWhitespaceOrNil)
    }

    /// `isWhitespaceOrNil` returns `true` if the string is empty.
    func test_isWhitespaceOrNil_empty() {
        let subject: String? = ""
        XCTAssertTrue(subject.isWhitespaceOrNil)
    }

    /// `isWhitespaceOrNil` returns `true` if the string is filled with whitespaces.
    func test_isWhitespaceOrNil_whitespaces() {
        let subject: String? = "      "
        XCTAssertTrue(subject.isWhitespaceOrNil)
    }

    /// `fallbackOnWhitespaceOrNil(fallback:)` returns `fallback`if string is `nil`.
    func test_fallbackOnWhitespaceOrNil_nil() {
        let fallback = "fallback"
        let subject: String? = nil

        let result = subject.fallbackOnWhitespaceOrNil(fallback: fallback)

        XCTAssertEqual(result, fallback)
    }

    /// `fallbackOnWhitespaceOrNil(fallback:)` returns `fallback`if string is empty.
    func test_fallbackOnWhitespaceOrNil_empty() {
        let fallback = "fallback"
        let subject: String? = ""

        let result = subject.fallbackOnWhitespaceOrNil(fallback: fallback)

        XCTAssertEqual(result, fallback)
    }

    /// `fallbackOnWhitespaceOrNil(fallback:)` returns `fallback`if string is full of whitespaces.
    func test_fallbackOnWhitespaceOrNil_whitespaces() {
        let fallback = "fallback"
        let subject: String? = "   "

        let result = subject.fallbackOnWhitespaceOrNil(fallback: fallback)

        XCTAssertEqual(result, fallback)
    }

    /// `fallbackOnWhitespaceOrNil(fallback:)` returns same string if has non-empty value without full whitespaces.
    func test_fallbackOnWhitespaceOrNil_value() {
        let fallback = "fallback"
        let subject: String? = "value"

        let result = subject.fallbackOnWhitespaceOrNil(fallback: fallback)

        XCTAssertEqual(result, subject)
    }

    /// `fallbackOnWhitespaceOrNil(fallback:)` returns same string if has non-empty value with some whitespaces.
    func test_fallbackOnWhitespaceOrNil_valueWithSomeWhitespaces() {
        let fallback = "fallback"
        let subject: String? = "   value   "

        let result = subject.fallbackOnWhitespaceOrNil(fallback: fallback)

        XCTAssertEqual(result, subject)
    }

    /// `fallbackOnWhitespaceOrNil(fallback:)` returns `nil`if string and fallback are `nil`.
    func test_fallbackOnWhitespaceOrNil_nilFallbackNil() {
        let fallback: String? = nil
        let subject: String? = nil

        let result = subject.fallbackOnWhitespaceOrNil(fallback: fallback)

        XCTAssertEqual(result, fallback)
    }

    /// `fallbackOnWhitespaceOrNil(fallback:)` returns `nil`if string is empty and fallback is `nil`.
    func test_fallbackOnWhitespaceOrNil_emptyFallbackNil() {
        let fallback: String? = nil
        let subject: String? = ""

        let result = subject.fallbackOnWhitespaceOrNil(fallback: fallback)

        XCTAssertEqual(result, fallback)
    }

    /// `fallbackOnWhitespaceOrNil(fallback:)` returns `nil`if string is full of whitespaces and fallback is `nil`.
    func test_fallbackOnWhitespaceOrNil_whitespacesFallbackNil() {
        let fallback: String? = nil
        let subject: String? = "   "

        let result = subject.fallbackOnWhitespaceOrNil(fallback: fallback)

        XCTAssertEqual(result, fallback)
    }

    /// `fallbackOnWhitespaceOrNil(fallback:)` returns same string if has non-empty value without full whitespaces.
    func test_fallbackOnWhitespaceOrNil_valueFallbackNil() {
        let fallback: String? = nil
        let subject: String? = "value"

        let result = subject.fallbackOnWhitespaceOrNil(fallback: fallback)

        XCTAssertEqual(result, subject)
    }

    /// `fallbackOnWhitespaceOrNil(fallback:)` returns same string if has non-empty value with some whitespaces.
    func test_fallbackOnWhitespaceOrNil_valueWithSomeWhitespacesFallbackNil() {
        let fallback: String? = nil
        let subject: String? = "   value   "

        let result = subject.fallbackOnWhitespaceOrNil(fallback: fallback)

        XCTAssertEqual(result, subject)
    }
}
