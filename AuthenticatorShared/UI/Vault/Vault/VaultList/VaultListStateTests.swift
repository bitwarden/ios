import XCTest

@testable import AuthenticatorShared

class VaultListStateTests: AuthenticatorTestCase {
    // MARK: Properties

    var subject: VaultListState!

    override func setUp() {
        super.setUp()

        subject = VaultListState()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `navigationTitle` returns the navigation bar title for the view.
    func test_navigationTitle() {
        XCTAssertEqual(subject.navigationTitle, "Localizations.myVault")
    }

    /// `userInitials` returns the user initials.
    func test_userInitials() {
        XCTAssertEqual(subject.userInitials, "..")
    }
}
