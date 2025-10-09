import XCTest

@testable import BitwardenShared

// MARK: - VaultGroupStateTests

class VaultGroupStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `newItemButtonType` returns the new item button type based on the group.
    func test_newItemButtonType() {
        let subjectCard = VaultGroupState(group: .card, vaultFilterType: .myVault)
        XCTAssertEqual(subjectCard.newItemButtonType, .button)

        let subjectIdentity = VaultGroupState(group: .identity, vaultFilterType: .myVault)
        XCTAssertEqual(subjectIdentity.newItemButtonType, .button)

        let subjectLogin = VaultGroupState(group: .login, vaultFilterType: .myVault)
        XCTAssertEqual(subjectLogin.newItemButtonType, .button)

        let subjectSecureNote = VaultGroupState(group: .secureNote, vaultFilterType: .myVault)
        XCTAssertEqual(subjectSecureNote.newItemButtonType, .button)

        let subjectCollection = VaultGroupState(
            group: .collection(id: "1", name: "Collection", organizationId: ""),
            vaultFilterType: .myVault,
        )
        XCTAssertEqual(subjectCollection.newItemButtonType, .menu)

        let subjectFolder = VaultGroupState(
            group: .folder(id: "1", name: "Folder"),
            vaultFilterType: .myVault,
        )
        XCTAssertEqual(subjectFolder.newItemButtonType, .menu)

        let subjectSSHKey = VaultGroupState(group: .sshKey, vaultFilterType: .myVault)
        XCTAssertNil(subjectSSHKey.newItemButtonType)

        let subjectTotp = VaultGroupState(group: .totp, vaultFilterType: .myVault)
        XCTAssertNil(subjectTotp.newItemButtonType)

        let subjectTrash = VaultGroupState(group: .trash, vaultFilterType: .myVault)
        XCTAssertNil(subjectTrash.newItemButtonType)
    }
}
