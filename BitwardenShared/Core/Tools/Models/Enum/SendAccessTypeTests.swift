import BitwardenResources
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - SendAccessTypeTests

class SendAccessTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `authType` returns the correct SDK `AuthType` for each access type.
    func test_authType() {
        XCTAssertEqual(SendAccessType.anyoneWithLink.authType, .none)
        XCTAssertEqual(SendAccessType.specificPeople.authType, .email)
        XCTAssertEqual(SendAccessType.anyoneWithPassword.authType, .password)
    }

    /// `init(authType:)` correctly initializes from SDK `AuthType`.
    func test_init_authType() {
        XCTAssertEqual(SendAccessType(authType: .none), .anyoneWithLink)
        XCTAssertEqual(SendAccessType(authType: .email), .specificPeople)
        XCTAssertEqual(SendAccessType(authType: .password), .anyoneWithPassword)
    }

    /// `localizedName` returns the correct localized string for each access type.
    func test_localizedName() {
        XCTAssertEqual(SendAccessType.anyoneWithLink.localizedName, Localizations.anyoneWithTheLink)
        XCTAssertEqual(SendAccessType.specificPeople.localizedName, Localizations.specificPeople)
        XCTAssertEqual(SendAccessType.anyoneWithPassword.localizedName, Localizations.anyoneWithPasswordSetByYou)
    }
}
