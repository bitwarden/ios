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

    /// `vaultFilterOptions` returns an empty set of filter options if there are no organizations.
    func test_vaultFilterOptions_noOrganizations() {
        XCTAssertEqual(subject.vaultFilterOptions, [])
    }

    /// `vaultFilterOptions` returns the filter options when organizations exist.
    func test_vaultFilterOptions_organizations() {
        subject.organizations = [
            Organization.fixture(id: "1", name: "Org 1"),
            Organization.fixture(id: "2", name: "Test Org"),
            Organization.fixture(id: "3", name: "ABC Org"),
        ]
        XCTAssertEqual(
            subject.vaultFilterOptions,
            [
                .allVaults,
                .myVault,
                .organization(Organization.fixture(id: "3", name: "ABC Org")),
                .organization(Organization.fixture(id: "1", name: "Org 1")),
                .organization(Organization.fixture(id: "2", name: "Test Org")),
            ]
        )
    }
}
