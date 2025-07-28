import XCTest

import BitwardenResources
@testable import BitwardenShared

class LanguageOptionTests: BitwardenTestCase {
    // MARK: Tests

    /// `allCases` returns the expected result.
    func test_allCases() {
        let allCases = LanguageOption.allCases
        XCTAssertEqual(allCases.first, .default)
        XCTAssertEqual(allCases[1], .custom(languageCode: "af"))
        XCTAssertEqual(allCases.count, 42)
    }

    /// `init` returns the correct values.
    func test_init() {
        XCTAssertEqual(LanguageOption(nil), .default)
        XCTAssertEqual(LanguageOption("de"), .custom(languageCode: "de"))
    }

    /// `title` returns the correct string.
    func test_title() {
        XCTAssertEqual(LanguageOption.default.title, Localizations.defaultSystem)
        XCTAssertEqual(LanguageOption.custom(languageCode: "de").title, "Deutsch")
    }

    /// `value` returns the correct string.
    func test_value() {
        XCTAssertNil(LanguageOption.default.value)
        XCTAssertEqual(LanguageOption.custom(languageCode: "de").value, "de")
    }
}
