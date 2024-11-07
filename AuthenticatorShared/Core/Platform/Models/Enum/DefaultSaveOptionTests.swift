import XCTest

@testable import AuthenticatorShared

class DefaultSaveOptionTests: AuthenticatorTestCase {
    // MARK: Tests

    /// `allCases` returns all of the cases in the correct order.
    func test_allCases() {
        XCTAssertEqual(
            DefaultSaveOption.allCases,
            [
                .saveToBitwarden,
                .saveLocally,
                .none,
            ]
        )
    }

    /// `localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(DefaultSaveOption.none.localizedName, Localizations.none)
        XCTAssertEqual(DefaultSaveOption.saveLocally.localizedName, Localizations.saveLocally)
        XCTAssertEqual(DefaultSaveOption.saveToBitwarden.localizedName, Localizations.saveToBitwarden)
    }

    /// `rawValue` returns the correct values.
    func test_rawValues() {
        XCTAssertEqual(DefaultSaveOption.none.rawValue, "none")
        XCTAssertEqual(DefaultSaveOption.saveLocally.rawValue, "saveLocally")
        XCTAssertEqual(DefaultSaveOption.saveToBitwarden.rawValue, "saveToBitwarden")
    }
}
