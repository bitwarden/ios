import BitwardenResources
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

        let subjectArchive = VaultGroupState(group: .archive, vaultFilterType: .myVault)
        XCTAssertNil(subjectArchive.newItemButtonType)

        let subjectTrash = VaultGroupState(group: .trash, vaultFilterType: .myVault)
        XCTAssertNil(subjectTrash.newItemButtonType)
    }

    /// `noItemsString` returns the appropriate message based on the group.
    func test_noItemsString() {
        let subjectArchive = VaultGroupState(group: .archive, vaultFilterType: .myVault)
        XCTAssertEqual(subjectArchive.noItemsString, Localizations.archiveEmptyDescriptionLong)

        let subjectCard = VaultGroupState(group: .card, vaultFilterType: .myVault)
        XCTAssertEqual(subjectCard.noItemsString, Localizations.thereAreNoCardsInYourVault)

        let subjectCollection = VaultGroupState(
            group: .collection(id: "1", name: "Collection", organizationId: ""),
            vaultFilterType: .myVault,
        )
        XCTAssertEqual(subjectCollection.noItemsString, Localizations.noItemsCollection)

        let subjectFolder = VaultGroupState(
            group: .folder(id: "1", name: "Folder"),
            vaultFilterType: .myVault,
        )
        XCTAssertEqual(subjectFolder.noItemsString, Localizations.noItemsFolder)

        let subjectIdentity = VaultGroupState(group: .identity, vaultFilterType: .myVault)
        XCTAssertEqual(subjectIdentity.noItemsString, Localizations.thereAreNoIdentitiesInYourVault)

        let subjectLogin = VaultGroupState(group: .login, vaultFilterType: .myVault)
        XCTAssertEqual(subjectLogin.noItemsString, Localizations.thereAreNoLoginsInYourVault)

        let subjectSecureNote = VaultGroupState(group: .secureNote, vaultFilterType: .myVault)
        XCTAssertEqual(subjectSecureNote.noItemsString, Localizations.thereAreNoNotesInYourVault)

        let subjectSSHKey = VaultGroupState(group: .sshKey, vaultFilterType: .myVault)
        XCTAssertEqual(subjectSSHKey.noItemsString, Localizations.thereAreNoSSHKeysInYourVault)

        let subjectTrash = VaultGroupState(group: .trash, vaultFilterType: .myVault)
        XCTAssertEqual(subjectTrash.noItemsString, Localizations.noItemsTrash)

        let subjectNoFolder = VaultGroupState(group: .noFolder, vaultFilterType: .myVault)
        XCTAssertEqual(subjectNoFolder.noItemsString, Localizations.noItems)

        let subjectTotp = VaultGroupState(group: .totp, vaultFilterType: .myVault)
        XCTAssertEqual(subjectTotp.noItemsString, Localizations.noItems)
    }

    /// `noItemsTitle` returns the appropriate title based on the group.
    func test_noItemsTitle() {
        let subjectArchive = VaultGroupState(group: .archive, vaultFilterType: .myVault)
        XCTAssertEqual(subjectArchive.noItemsTitle, Localizations.archiveIsEmpty)

        let subjectCard = VaultGroupState(group: .card, vaultFilterType: .myVault)
        XCTAssertNil(subjectCard.noItemsTitle)

        let subjectCollection = VaultGroupState(
            group: .collection(id: "1", name: "Collection", organizationId: ""),
            vaultFilterType: .myVault,
        )
        XCTAssertNil(subjectCollection.noItemsTitle)

        let subjectFolder = VaultGroupState(
            group: .folder(id: "1", name: "Folder"),
            vaultFilterType: .myVault,
        )
        XCTAssertNil(subjectFolder.noItemsTitle)

        let subjectIdentity = VaultGroupState(group: .identity, vaultFilterType: .myVault)
        XCTAssertNil(subjectIdentity.noItemsTitle)

        let subjectLogin = VaultGroupState(group: .login, vaultFilterType: .myVault)
        XCTAssertNil(subjectLogin.noItemsTitle)

        let subjectSecureNote = VaultGroupState(group: .secureNote, vaultFilterType: .myVault)
        XCTAssertNil(subjectSecureNote.noItemsTitle)

        let subjectSSHKey = VaultGroupState(group: .sshKey, vaultFilterType: .myVault)
        XCTAssertNil(subjectSSHKey.noItemsTitle)

        let subjectTrash = VaultGroupState(group: .trash, vaultFilterType: .myVault)
        XCTAssertNil(subjectTrash.noItemsTitle)

        let subjectNoFolder = VaultGroupState(group: .noFolder, vaultFilterType: .myVault)
        XCTAssertNil(subjectNoFolder.noItemsTitle)

        let subjectTotp = VaultGroupState(group: .totp, vaultFilterType: .myVault)
        XCTAssertNil(subjectTotp.noItemsTitle)
    }

    /// `showArchivePremiumSubscriptionEndedCard` returns `true` when the user doesn't have premium
    /// and is viewing the archive group.
    func test_showArchivePremiumSubscriptionEndedCard() {
        let subjectNoPremiumArchive = VaultGroupState(
            group: .archive,
            hasPremium: false,
            vaultFilterType: .myVault
        )
        XCTAssertTrue(subjectNoPremiumArchive.showArchivePremiumSubscriptionEndedCard)

        let subjectHasPremiumArchive = VaultGroupState(
            group: .archive,
            hasPremium: true,
            vaultFilterType: .myVault
        )
        XCTAssertFalse(subjectHasPremiumArchive.showArchivePremiumSubscriptionEndedCard)

        let subjectNoPremiumLogin = VaultGroupState(
            group: .login,
            hasPremium: false,
            vaultFilterType: .myVault
        )
        XCTAssertFalse(subjectNoPremiumLogin.showArchivePremiumSubscriptionEndedCard)

        let subjectHasPremiumLogin = VaultGroupState(
            group: .login,
            hasPremium: true,
            vaultFilterType: .myVault
        )
        XCTAssertFalse(subjectHasPremiumLogin.showArchivePremiumSubscriptionEndedCard)
    }
}
