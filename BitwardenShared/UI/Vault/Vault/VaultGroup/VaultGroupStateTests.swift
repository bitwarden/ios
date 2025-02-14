import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - VaultGroupStateTests

class VaultGroupStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `floatingActionButtonType` returns the floating action button type based on the group.
    func test_floatingActionButtonType() {
        let subjectCard = VaultGroupState(group: .card, vaultFilterType: .myVault)
        XCTAssertEqual(subjectCard.floatingActionButtonType, .button)

        let subjectIdentity = VaultGroupState(group: .identity, vaultFilterType: .myVault)
        XCTAssertEqual(subjectIdentity.floatingActionButtonType, .button)

        let subjectLogin = VaultGroupState(group: .login, vaultFilterType: .myVault)
        XCTAssertEqual(subjectLogin.floatingActionButtonType, .button)

        let subjectSecureNote = VaultGroupState(group: .secureNote, vaultFilterType: .myVault)
        XCTAssertEqual(subjectSecureNote.floatingActionButtonType, .button)

        let subjectCollection = VaultGroupState(
            group: .collection(id: "1", name: "Collection", organizationId: ""),
            vaultFilterType: .myVault
        )
        XCTAssertEqual(subjectCollection.floatingActionButtonType, .menu)

        let subjectFolder = VaultGroupState(
            group: .folder(id: "1", name: "Folder"),
            vaultFilterType: .myVault
        )
        XCTAssertEqual(subjectFolder.floatingActionButtonType, .menu)

        let subjectSSHKey = VaultGroupState(group: .sshKey, vaultFilterType: .myVault)
        XCTAssertNil(subjectSSHKey.floatingActionButtonType)

        let subjectTotp = VaultGroupState(group: .totp, vaultFilterType: .myVault)
        XCTAssertNil(subjectTotp.floatingActionButtonType)

        let subjectTrash = VaultGroupState(group: .trash, vaultFilterType: .myVault)
        XCTAssertNil(subjectTrash.floatingActionButtonType)
    }
}
