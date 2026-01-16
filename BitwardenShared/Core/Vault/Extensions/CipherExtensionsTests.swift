import BitwardenSdk
import BitwardenSharedMocks
import XCTest

@testable import BitwardenShared

// MARK: - CipherExtensionsTests

class CipherExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `belongsToGroup(_:)` returns `true` when the cipher is archived and the group is `.archive`.
    func test_belongsToGroup_archive() {
        let cipher = Cipher.fixture(archivedDate: .now, type: .login)
        XCTAssertTrue(cipher.belongsToGroup(.archive))
        XCTAssertFalse(cipher.belongsToGroup(.card))
        XCTAssertFalse(cipher.belongsToGroup(.identity))
        XCTAssertFalse(Cipher.fixture(archivedDate: nil, type: .login).belongsToGroup(.archive))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is a card type and the group is `.card`.
    func test_belongsToGroup_card() {
        let cipher = Cipher.fixture(type: .card)
        XCTAssertTrue(cipher.belongsToGroup(.card))
        XCTAssertFalse(cipher.belongsToGroup(.login))
        XCTAssertFalse(cipher.belongsToGroup(.identity))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is a login type and the group is `.login`.
    func test_belongsToGroup_login() {
        let cipher = Cipher.fixture(type: .login)
        XCTAssertTrue(cipher.belongsToGroup(.login))
        XCTAssertFalse(cipher.belongsToGroup(.card))
        XCTAssertFalse(cipher.belongsToGroup(.identity))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is an identity type and the group is `.identity`.
    func test_belongsToGroup_identity() {
        let cipher = Cipher.fixture(type: .identity)
        XCTAssertTrue(cipher.belongsToGroup(.identity))
        XCTAssertFalse(cipher.belongsToGroup(.card))
        XCTAssertFalse(cipher.belongsToGroup(.login))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is a secure note type and the group is `.secureNote`.
    func test_belongsToGroup_secureNote() {
        let cipher = Cipher.fixture(type: .secureNote)
        XCTAssertTrue(cipher.belongsToGroup(.secureNote))
        XCTAssertFalse(cipher.belongsToGroup(.card))
        XCTAssertFalse(cipher.belongsToGroup(.login))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is an SSH key type and the group is `.sshKey`.
    func test_belongsToGroup_sshKey() {
        let cipher = Cipher.fixture(type: .sshKey)
        XCTAssertTrue(cipher.belongsToGroup(.sshKey))
        XCTAssertFalse(cipher.belongsToGroup(.card))
        XCTAssertFalse(cipher.belongsToGroup(.login))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is a login with TOTP and the group is `.totp`.
    func test_belongsToGroup_totp() {
        let cipher = Cipher.fixture(
            login: .fixture(totp: "JBSWY3DPEHPK3PXP"),
            type: .login,
        )
        XCTAssertTrue(cipher.belongsToGroup(.totp))
        XCTAssertTrue(cipher.belongsToGroup(.login))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher is a login without TOTP and the group is `.totp`.
    func test_belongsToGroup_totp_noTotp() {
        let cipher = Cipher.fixture(
            login: .fixture(totp: nil),
            type: .login,
        )
        XCTAssertFalse(cipher.belongsToGroup(.totp))
        XCTAssertTrue(cipher.belongsToGroup(.login))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher is not a login and the group is `.totp`.
    func test_belongsToGroup_totp_nonLogin() {
        let cipher = Cipher.fixture(type: .card)
        XCTAssertFalse(cipher.belongsToGroup(.totp))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher has no folder and the group is `.noFolder`.
    func test_belongsToGroup_noFolder() {
        let cipher = Cipher.fixture(folderId: nil)
        XCTAssertTrue(cipher.belongsToGroup(.noFolder))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher has a folder and the group is `.noFolder`.
    func test_belongsToGroup_noFolder_hasFolder() {
        let cipher = Cipher.fixture(folderId: "folder-123")
        XCTAssertFalse(cipher.belongsToGroup(.noFolder))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher's folder ID matches the group's folder ID.
    func test_belongsToGroup_folder_matching() {
        let cipher = Cipher.fixture(folderId: "folder-123")
        XCTAssertTrue(cipher.belongsToGroup(.folder(id: "folder-123", name: "My Folder")))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher's folder ID doesn't match the group's folder ID.
    func test_belongsToGroup_folder_notMatching() {
        let cipher = Cipher.fixture(folderId: "folder-123")
        XCTAssertFalse(cipher.belongsToGroup(.folder(id: "folder-456", name: "Other Folder")))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher has no folder and the group is a specific folder.
    func test_belongsToGroup_folder_noFolderId() {
        let cipher = Cipher.fixture(folderId: nil)
        XCTAssertFalse(cipher.belongsToGroup(.folder(id: "folder-123", name: "My Folder")))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher belongs to a collection that matches the group.
    func test_belongsToGroup_collection_matching() {
        let cipher = Cipher.fixture(collectionIds: ["collection-123", "collection-456"])
        XCTAssertTrue(cipher.belongsToGroup(.collection(
            id: "collection-123",
            name: "My Collection",
            organizationId: "org-1",
        )))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher doesn't belong to the collection.
    func test_belongsToGroup_collection_notMatching() {
        let cipher = Cipher.fixture(collectionIds: ["collection-123"])
        XCTAssertFalse(cipher.belongsToGroup(.collection(
            id: "collection-789",
            name: "Other Collection",
            organizationId: "org-1",
        )))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher has no collections and the group is a collection.
    func test_belongsToGroup_collection_noCollections() {
        let cipher = Cipher.fixture(collectionIds: [])
        XCTAssertFalse(cipher.belongsToGroup(.collection(
            id: "collection-123",
            name: "My Collection",
            organizationId: "org-1",
        )))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is deleted and the group is `.trash`.
    func test_belongsToGroup_trash() {
        let cipher = Cipher.fixture(deletedDate: Date())
        XCTAssertTrue(cipher.belongsToGroup(.trash))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher is not deleted and the group is `.trash`.
    func test_belongsToGroup_trash_notDeleted() {
        let cipher = Cipher.fixture(deletedDate: nil)
        XCTAssertFalse(cipher.belongsToGroup(.trash))
    }

    /// `isHidden` return `true` when the cipher is hidden, i.e. archived or deleted; `false` otherwise.
    func test_isHidden() {
        XCTAssertTrue(Cipher.fixture(archivedDate: .now).isHidden)
        XCTAssertTrue(Cipher.fixture(deletedDate: .now).isHidden)
        XCTAssertTrue(Cipher.fixture(archivedDate: .now, deletedDate: .now).isHidden)
        XCTAssertFalse(Cipher.fixture(archivedDate: nil, deletedDate: nil).isHidden)
    }
}
