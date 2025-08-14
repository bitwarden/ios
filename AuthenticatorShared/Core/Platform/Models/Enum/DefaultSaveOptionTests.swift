import BitwardenResources
import XCTest

@testable import AuthenticatorShared

class DefaultSaveOptionTests: BitwardenTestCase {
    // MARK: Tests

    /// `allCases` returns all of the cases in the correct order.
    func test_allCases() {
        XCTAssertEqual(
            DefaultSaveOption.allCases,
            [
                .saveToBitwarden,
                .saveHere,
                .none,
            ]
        )
    }

    /// `localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(DefaultSaveOption.none.localizedName, Localizations.none)
        XCTAssertEqual(DefaultSaveOption.saveHere.localizedName, Localizations.saveHere)
        XCTAssertEqual(DefaultSaveOption.saveToBitwarden.localizedName, Localizations.saveToBitwarden)
    }

    /// `rawValue` returns the correct values.
    func test_rawValues() {
        XCTAssertEqual(DefaultSaveOption.none.rawValue, "none")
        XCTAssertEqual(DefaultSaveOption.saveHere.rawValue, "saveHere")
        XCTAssertEqual(DefaultSaveOption.saveToBitwarden.rawValue, "saveToBitwarden")
    }
}
