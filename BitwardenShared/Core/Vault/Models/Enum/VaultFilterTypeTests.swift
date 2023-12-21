import XCTest

@testable import BitwardenShared

class VaultFilterTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `filterTitle` returns the title of the applied filter.
    func test_filterTitle() {
        XCTAssertEqual(VaultFilterType.allVaults.filterTitle, "Vaults: All")
        XCTAssertEqual(VaultFilterType.myVault.filterTitle, "Vault: My vault")
        XCTAssertEqual(
            VaultFilterType.organization(Organization(id: "", name: "Test Organization")).filterTitle,
            "Vault: Test Organization"
        )
    }

    /// `title` returns the title of filter for displaying in the filter menu.
    func test_title() {
        XCTAssertEqual(VaultFilterType.allVaults.title, "All vaults")
        XCTAssertEqual(VaultFilterType.myVault.title, "My vault")
        XCTAssertEqual(
            VaultFilterType.organization(Organization(id: "", name: "Test Organization")).title,
            "Test Organization"
        )
    }
}
