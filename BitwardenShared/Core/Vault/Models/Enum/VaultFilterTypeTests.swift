import XCTest

@testable import BitwardenShared

class VaultFilterTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `collectionFilter(_:)` returns whether the collection should be included in the all vaults list.
    func test_collectionFilter_allVaults() {
        XCTAssertTrue(VaultFilterType.allVaults.collectionFilter(.fixture(organizationId: "1")))
        XCTAssertTrue(VaultFilterType.allVaults.collectionFilter(.fixture(organizationId: "2")))
    }

    /// `collectionFilter(_:)` returns whether the collection should be included in the my vault list.
    func test_collectionFilter_myVaults() {
        XCTAssertFalse(VaultFilterType.myVault.collectionFilter(.fixture(organizationId: "1")))
        XCTAssertFalse(VaultFilterType.myVault.collectionFilter(.fixture(organizationId: "2")))
    }

    /// `collectionFilter(_:)` returns whether the collection should be included in the organization vault list.
    func test_collectionFilter_organization() {
        XCTAssertTrue(
            VaultFilterType.organization(.fixture(id: "1"))
                .collectionFilter(.fixture(organizationId: "1"))
        )
        XCTAssertFalse(
            VaultFilterType.organization(.fixture(id: "1"))
                .collectionFilter(.fixture(organizationId: "2"))
        )
    }

    /// `cipherFilter(_:)` returns whether the cipher should be included in the all vaults list.
    func test_filterCipher_allVaults() {
        XCTAssertTrue(VaultFilterType.allVaults.cipherFilter(.fixture(organizationId: nil)))
        XCTAssertTrue(VaultFilterType.allVaults.cipherFilter(.fixture(organizationId: "1")))
    }

    /// `cipherFilter(_:)` returns whether the cipher should be included in the my vault list.
    func test_filterCipher_myVault() {
        XCTAssertTrue(VaultFilterType.myVault.cipherFilter(.fixture(organizationId: nil)))
        XCTAssertFalse(VaultFilterType.myVault.cipherFilter(.fixture(organizationId: "1")))
    }

    /// `cipherFilter(_:)` returns whether the cipher should be included in the organization vault list.
    func test_filterCipher_organization() {
        XCTAssertTrue(
            VaultFilterType.organization(.fixture(id: "1"))
                .cipherFilter(.fixture(organizationId: "1"))
        )
        XCTAssertFalse(
            VaultFilterType.organization(.fixture(id: "1"))
                .cipherFilter(.fixture(organizationId: nil))
        )
        XCTAssertFalse(
            VaultFilterType.organization(.fixture(id: "1"))
                .cipherFilter(.fixture(organizationId: "2"))
        )
    }

    /// `filterTitle` returns the title of the applied filter.
    func test_filterTitle() {
        XCTAssertEqual(VaultFilterType.allVaults.filterTitle, "Vaults: All")
        XCTAssertEqual(VaultFilterType.myVault.filterTitle, "Vault: My vault")
        XCTAssertEqual(
            VaultFilterType.organization(.fixture(id: "", name: "Test Organization")).filterTitle,
            "Vault: Test Organization"
        )
    }

    /// `folderFilter(_:)` returns that folders are always included in the all vaults lists
    func test_folderFilter_allVaults() {
        XCTAssertTrue(VaultFilterType.allVaults.folderFilter(.fixtureGroup(count: 0)))
        XCTAssertTrue(VaultFilterType.allVaults.folderFilter(.fixtureGroup(count: 1)))
    }

    /// `folderFilter(_:)` returns that folders are included in the my vaults list if they aren't empty.
    func test_folderFilter_myVaults() {
        XCTAssertFalse(VaultFilterType.myVault.folderFilter(.fixtureGroup(count: 0)))
        XCTAssertTrue(VaultFilterType.myVault.folderFilter(.fixtureGroup(count: 1)))
    }

    /// `folderFilter(_:)` returns that folders are included in the organization vault list if they aren't empty.
    func test_folderFilter_organization() {
        XCTAssertFalse(VaultFilterType.organization(.fixture()).folderFilter(.fixtureGroup(count: 0)))
        XCTAssertTrue(VaultFilterType.organization(.fixture()).folderFilter(.fixtureGroup(count: 1)))
    }

    /// `title` returns the title of filter for displaying in the filter menu.
    func test_title() {
        XCTAssertEqual(VaultFilterType.allVaults.title, "All vaults")
        XCTAssertEqual(VaultFilterType.myVault.title, "My vault")
        XCTAssertEqual(
            VaultFilterType.organization(.fixture(id: "", name: "Test Organization")).title,
            "Test Organization"
        )
    }
}
