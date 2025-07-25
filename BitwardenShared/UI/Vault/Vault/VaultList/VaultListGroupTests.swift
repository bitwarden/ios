import BitwardenResources
import XCTest

@testable import BitwardenShared

// MARK: - VaultListGroupTests

class VaultListGroupTests: BitwardenTestCase {
    // MARK: Tests

    /// `collectionId` returns the collection's ID, if the group is a collection.
    func test_collectionId() {
        XCTAssertNil(VaultListGroup.card.collectionId)
        XCTAssertEqual(
            VaultListGroup.collection(id: "1234", name: "Collection 🗂️", organizationId: "ABCD").collectionId,
            "1234"
        )
        XCTAssertNil(VaultListGroup.folder(id: "4321", name: "Folder 📁").collectionId)
        XCTAssertNil(VaultListGroup.identity.collectionId)
        XCTAssertNil(VaultListGroup.login.collectionId)
        XCTAssertNil(VaultListGroup.secureNote.collectionId)
        XCTAssertNil(VaultListGroup.sshKey.collectionId)
        XCTAssertNil(VaultListGroup.totp.collectionId)
        XCTAssertNil(VaultListGroup.trash.collectionId)
    }

    /// `isFolder` returns whether the group is a folder.
    func test_isFolder() {
        XCTAssertFalse(VaultListGroup.card.isFolder)
        XCTAssertFalse(VaultListGroup.collection(id: "", name: "", organizationId: "").isFolder)
        XCTAssertTrue(VaultListGroup.folder(id: "1", name: "Folder").isFolder)
        XCTAssertFalse(VaultListGroup.identity.isFolder)
        XCTAssertFalse(VaultListGroup.login.isFolder)
        XCTAssertFalse(VaultListGroup.noFolder.isFolder)
        XCTAssertFalse(VaultListGroup.secureNote.isFolder)
        XCTAssertFalse(VaultListGroup.sshKey.isFolder)
        XCTAssertFalse(VaultListGroup.totp.isFolder)
        XCTAssertFalse(VaultListGroup.trash.isFolder)
    }

    /// `folderId` returns the folders's ID, if the group is a folder.
    func test_folderId() {
        XCTAssertNil(VaultListGroup.card.folderId)
        XCTAssertNil(
            VaultListGroup.collection(id: "1234", name: "Collection 🗂️", organizationId: "ABCD").folderId
        )
        XCTAssertEqual(VaultListGroup.folder(id: "4321", name: "Folder 📁").folderId, "4321")
        XCTAssertNil(VaultListGroup.identity.folderId)
        XCTAssertNil(VaultListGroup.login.folderId)
        XCTAssertNil(VaultListGroup.secureNote.folderId)
        XCTAssertNil(VaultListGroup.sshKey.folderId)
        XCTAssertNil(VaultListGroup.totp.folderId)
        XCTAssertNil(VaultListGroup.trash.folderId)
    }

    /// `name` returns the display name of the group.
    func test_name() {
        XCTAssertEqual(VaultListGroup.card.name, "Card")
        XCTAssertEqual(
            VaultListGroup.collection(id: "", name: "Collection 🗂️", organizationId: "1").name,
            "Collection 🗂️"
        )
        XCTAssertEqual(VaultListGroup.folder(id: "", name: "Folder 📁").name, "Folder 📁")
        XCTAssertEqual(VaultListGroup.identity.name, "Identity")
        XCTAssertEqual(VaultListGroup.login.name, "Login")
        XCTAssertEqual(VaultListGroup.secureNote.name, "Secure note")
        XCTAssertEqual(VaultListGroup.sshKey.name, "SSH key")
        XCTAssertEqual(VaultListGroup.totp.name, Localizations.verificationCodes)
        XCTAssertEqual(VaultListGroup.trash.name, "Trash")
    }

    /// `navigationTitle` returns the navigation title of the group.
    func test_navigationTitle() {
        XCTAssertEqual(VaultListGroup.card.navigationTitle, Localizations.cards)
        XCTAssertEqual(
            VaultListGroup.collection(id: "", name: "Collection 🗂️", organizationId: "1").navigationTitle,
            "Collection 🗂️"
        )
        XCTAssertEqual(VaultListGroup.folder(id: "", name: "Folder 📁").navigationTitle, "Folder 📁")
        XCTAssertEqual(VaultListGroup.identity.navigationTitle, Localizations.identities)
        XCTAssertEqual(VaultListGroup.login.navigationTitle, Localizations.logins)
        XCTAssertEqual(VaultListGroup.secureNote.navigationTitle, Localizations.secureNotes)
        XCTAssertEqual(VaultListGroup.sshKey.navigationTitle, Localizations.sshKeys)
        XCTAssertEqual(VaultListGroup.totp.navigationTitle, Localizations.verificationCodes)
        XCTAssertEqual(VaultListGroup.trash.navigationTitle, Localizations.trash)
    }

    /// `organizationId` returns the organization's ID of the collection, if the group is a collection.
    func test_organizationId() {
        XCTAssertNil(VaultListGroup.card.organizationId)
        XCTAssertEqual(
            VaultListGroup.collection(id: "1234", name: "Collection 🗂️", organizationId: "ABCD").organizationId,
            "ABCD"
        )
        XCTAssertNil(VaultListGroup.folder(id: "4321", name: "Folder 📁").organizationId)
        XCTAssertNil(VaultListGroup.identity.organizationId)
        XCTAssertNil(VaultListGroup.login.organizationId)
        XCTAssertNil(VaultListGroup.secureNote.organizationId)
        XCTAssertNil(VaultListGroup.sshKey.organizationId)
        XCTAssertNil(VaultListGroup.totp.organizationId)
        XCTAssertNil(VaultListGroup.trash.organizationId)
    }
}
