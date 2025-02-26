import Foundation
import XCTest

@testable import BitwardenShared

class SearchVaultFilterRowStateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: SearchVaultFilterRowState!

    override func setUp() {
        super.setUp()

        subject = SearchVaultFilterRowState()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

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

    /// `vaultFilterOptions` returns no filter options if organizations exist but the filter should be hidden.
    func test_vaultFilterOptions_organizationsShouldNotShowVaultFilter() {
        subject.organizations = [
            Organization.fixture(id: "1", name: "Org 1"),
            Organization.fixture(id: "2", name: "Test Org"),
            Organization.fixture(id: "3", name: "ABC Org"),
        ]
        subject.canShowVaultFilter = false
        XCTAssertEqual(subject.vaultFilterOptions, [])
    }

    /// `vaultFilterOptions` returns the filter organization filter options if personal ownership is disabled.
    func test_vaultFilterOptions_personalOwnershipDisabled() {
        subject.organizations = [
            Organization.fixture(id: "1", name: "Org 1"),
            Organization.fixture(id: "2", name: "Test Org"),
            Organization.fixture(id: "3", name: "ABC Org"),
        ]
        subject.isPersonalOwnershipDisabled = true
        XCTAssertEqual(
            subject.vaultFilterOptions,
            [
                .allVaults,
                .organization(Organization.fixture(id: "3", name: "ABC Org")),
                .organization(Organization.fixture(id: "1", name: "Org 1")),
                .organization(Organization.fixture(id: "2", name: "Test Org")),
            ]
        )
    }
}
