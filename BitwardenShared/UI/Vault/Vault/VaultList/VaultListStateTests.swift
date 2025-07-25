import BitwardenResources
import XCTest

@testable import BitwardenShared

class VaultListStateTests: BitwardenTestCase {
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
        XCTAssertEqual(subject.navigationTitle, Localizations.myVault)

        subject.organizations = [
            Organization.fixture(id: "1", name: "Org 1"),
        ]
        XCTAssertEqual(subject.navigationTitle, Localizations.vaults)
    }

    /// `userInitials` returns the user initials.
    func test_userInitials() {
        XCTAssertEqual(subject.userInitials, "..")
    }
}
