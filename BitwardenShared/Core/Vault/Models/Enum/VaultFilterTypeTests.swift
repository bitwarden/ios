import BitwardenSdk
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

    /// `folderFilter(_:)` includes empty folders when filtering on all vaults.
    func test_folderFilter_allVaults_emptyFolder() {
        let folder = FolderView.fixture(id: "1")
        let ciphers = [
            CipherView.fixture(folderId: "2"),
            CipherView.fixture(folderId: "3"),
        ]
        XCTAssertTrue(VaultFilterType.allVaults.folderFilter(folder, ciphers: ciphers))
    }

    /// `folderFilter(_:)` includes non-empty folders when filtering on all vaults.
    func test_folderFilter_allVaults_nonemptyFolder() {
        let folder = FolderView.fixture(id: "1")
        let ciphers = [
            CipherView.fixture(folderId: "1"),
            CipherView.fixture(folderId: "2"),
        ]
        XCTAssertTrue(VaultFilterType.allVaults.folderFilter(folder, ciphers: ciphers))
    }

    /// `folderFilter(_:)` excludes empty folders when filtering on my vault.
    func test_folderFilter_myVault_emptyFolder() {
        let folder = FolderView.fixture(id: "1")
        let ciphers = [
            CipherView.fixture(folderId: "2"),
            CipherView.fixture(folderId: "3"),
        ]
        XCTAssertFalse(VaultFilterType.myVault.folderFilter(folder, ciphers: ciphers))
    }

    /// `folderFilter(_:)` includes non-empty folders when filtering on my vault.
    func test_folderFilter_myVault_nonemptyFolders() {
        let folder = FolderView.fixture(id: "1")
        let ciphers = [
            CipherView.fixture(folderId: "1"),
            CipherView.fixture(folderId: "2"),
        ]
        XCTAssertTrue(VaultFilterType.myVault.folderFilter(folder, ciphers: ciphers))
    }

    /// `folderFilter(_:)` excludes empty folders when filtering on an organization.
    func test_folderFilter_organization_emptyFolder() {
        let folder = FolderView.fixture(id: "1")
        let ciphers = [
            CipherView.fixture(folderId: "2"),
            CipherView.fixture(folderId: "3"),
        ]
        XCTAssertFalse(VaultFilterType.organization(.fixture()).folderFilter(folder, ciphers: ciphers))
    }

    /// `folderFilter(_:)` includes non-empty folders when filtering on an organization.
    func test_folderFilter_organization_nonemptyFolder() {
        let folder = FolderView.fixture(id: "1")
        let ciphers = [
            CipherView.fixture(folderId: "1"),
            CipherView.fixture(folderId: "2"),
        ]
        XCTAssertTrue(VaultFilterType.organization(.fixture()).folderFilter(folder, ciphers: ciphers))
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
