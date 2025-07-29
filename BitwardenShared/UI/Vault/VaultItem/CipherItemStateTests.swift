import BitwardenResources
import BitwardenSdk
import Foundation
import XCTest

@testable import BitwardenShared

class CipherItemStateTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Tests

    /// `init(cloneItem: hasPremium)` returns a cloned CipherItemState.
    func test_init_clone() {
        let cipher = CipherView.loginFixture(login: .fixture(fido2Credentials: [.fixture()]))
        let state = CipherItemState(cloneItem: cipher, hasPremium: true)
        XCTAssertEqual(state.name, "\(cipher.name) - \(Localizations.clone)")
        XCTAssertNil(state.cipher.id)
        XCTAssertEqual(state.accountHasPremium, true)
        XCTAssertEqual(state.cardItemState, cipher.cardItemState())
        XCTAssertEqual(state.configuration, .add)
        XCTAssertEqual(state.customFieldsState, .init(cipherType: .login, customFields: cipher.customFields))
        XCTAssertEqual(state.folderId, cipher.folderId)
        XCTAssertEqual(state.identityState, cipher.identityItemState())
        XCTAssertEqual(state.isFavoriteOn, cipher.favorite)
        XCTAssertEqual(state.isMasterPasswordRePromptOn, cipher.reprompt == .password)
        XCTAssertEqual(state.loginState, cipher.loginItemState(excludeFido2Credentials: true, showTOTP: true))
        XCTAssertTrue(state.loginState.fido2Credentials.isEmpty)
        XCTAssertEqual(state.notes, cipher.notes ?? "")
        XCTAssertEqual(state.sshKeyState, cipher.sshKeyItemState())
        XCTAssertEqual(state.type, .init(type: cipher.type))
        XCTAssertEqual(state.updatedDate, cipher.revisionDate)
    }

    /// `init(existing:hasPremium:)` sets `isReadOnly` to false if the user does have permission to edit.
    func test_init_existing_isReadOnly() throws {
        let cipher = CipherView.loginFixture(edit: true)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertFalse(state.isReadOnly)
    }

    /// `init(existing:hasPremium:)` sets `isReadOnly` to true if the user does not have permission to edit.
    func test_init_existing_isReadOnly_true() throws {
        let cipher = CipherView.loginFixture(edit: false)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.isReadOnly)
    }

    /// `init(existing:hasPremium:)` sets `loginState.isTOTPAvailable` to false if the user doesn't
    /// have premium and the organization doesn't use TOTP.
    func test_init_existing_isTOTPAvailable_notAvailable() throws {
        let cipher = CipherView.loginFixture(login: .fixture())
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false))
        XCTAssertFalse(state.loginState.isTOTPAvailable)
    }

    /// `init(existing:hasPremium:)` sets `loginState.isTOTPAvailable` to true if the user has premium.
    func test_init_existing_isTOTPAvailable_premium() throws {
        let cipher = CipherView.loginFixture(login: .fixture())
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.loginState.isTOTPAvailable)
    }

    /// `init(existing:hasPremium:)` sets `loginState.isTOTPAvailable` to true if the organization uses TOTP.
    func test_init_existing_isTOTPAvailable_organizationUseTotp() throws {
        let cipher = CipherView.loginFixture(login: .fixture(), organizationUseTotp: true)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false))
        XCTAssertTrue(state.loginState.isTOTPAvailable)
    }

    /// `canBeDeleted` is true
    /// if the cipher does not belong to a collection
    func test_canBeDeleted_notCollection() throws {
        let cipher = CipherView.loginFixture(login: .fixture())
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.canBeDeleted)

        state.allUserCollections = [CollectionView.fixture()]
        XCTAssertTrue(state.canBeDeleted)
    }

    /// `canBeDeleted` is true
    ///  if the cipher belongs to a collection
    ///  and the user has manage permissions for that collection
    func test_canBeDeleted_canManageOneCollection() throws {
        let cipher = CipherView.loginFixture(collectionIds: ["1"], login: .fixture())
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.allUserCollections = [CollectionView.fixture(id: "1", manage: true)]
        XCTAssertTrue(state.canBeDeleted)
    }

    /// `canBeDeleted` is false
    /// if the cipher belongs to a collection
    /// and the user does not have manage permissions for that collection
    func test_canBeDeleted_cannotManageOneCollection() throws {
        let cipher = CipherView.loginFixture(collectionIds: ["1"], login: .fixture())
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.allUserCollections = [CollectionView.fixture(id: "1", manage: false)]
        XCTAssertFalse(state.canBeDeleted)
    }

    /// `canBeDeleted` is false
    /// if the cipher belongs to multiple collections
    /// and the user does not have manage permissions for any of those collections
    func test_canBeDeleted_cannotManageAnyCollection() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            login: .fixture()
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.allUserCollections = [
            CollectionView.fixture(id: "1", manage: false),
            CollectionView.fixture(id: "2", manage: false),
        ]
        XCTAssertFalse(state.canBeDeleted)
    }

    /// `canBeDeleted` is true
    /// if the cipher belongs to multiple collections
    /// and the user has manage permissions for any of those collections
    func test_canBeDeleted_canManageAnyCollection() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            login: .fixture()
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.allUserCollections = [
            CollectionView.fixture(id: "1", manage: true),
            CollectionView.fixture(id: "2", manage: false),
        ]
        XCTAssertTrue(state.canBeDeleted)
    }

    /// `canBeDeleted` returns value from cipher permissions if not nil
    /// delete value true
    func test_canBeDeletedPermission_true() throws {
        let cipher = CipherView.loginFixture(
            login: .fixture(),
            permissions: CipherPermissions(
                delete: true,
                restore: true
            )
        )
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.canBeDeleted)
    }

    /// `canBeDeleted` returns value from cipher permissions if not nil
    /// delete value false
    func test_canBeDeletedPermission_false() throws {
        let cipher = CipherView.loginFixture(
            login: .fixture(),
            permissions: CipherPermissions(
                delete: false,
                restore: true
            )
        )
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertFalse(state.canBeDeleted)
    }

    /// `canBeRestored` cipher permissions is nil fallback to isSoftDeleted
    func test_canBeRestored_permissions_nil() throws {
        var cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            deletedDate: nil,
            login: .fixture(),
            permissions: nil
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertFalse(state.canBeRestored)

        cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            deletedDate: Date(),
            login: .fixture(),
            permissions: nil
        )
        state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.canBeRestored)
    }

    /// `canBeRestored` returns value from cipher permissions if not nil
    /// restore value true
    func test_canBeRestored_true() throws {
        let cipher = CipherView.loginFixture(
            deletedDate: Date(),
            login: .fixture(),
            permissions: CipherPermissions(
                delete: true,
                restore: true
            )
        )
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.canBeRestored)
    }

    /// `canBeRestored` returns value from cipher permissions if not nil
    /// restore value false
    func test_canBeRestored_false() throws {
        let cipher = CipherView.loginFixture(
            deletedDate: Date(),
            login: .fixture(),
            permissions: CipherPermissions(
                delete: true,
                restore: false
            )
        )
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertFalse(state.canBeRestored)
    }

    /// `hasOrganizations` is true when the cipher has a non-nil organizationId.
    func test_hasOrganizations_whenCipherBelongsToAnOrg_returnsTrue() throws {
        let cipher = CipherView.fixture(organizationId: "org123")

        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.hasOrganizations)
    }

    /// `hasOrganizations` is false when ownership options are only personal and organizationId is nil.
    func test_hasOrganizations_whenCipherBelongsToPersonal_returnsFalse() throws {
        let cipher = CipherView.fixture()
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.ownershipOptions = [CipherOwner.personal(email: "user@bitwarden")]

        XCTAssertFalse(state.hasOrganizations)
    }

    /// `hasOrganizations` is true when ownership options include at least one non-personal option.
    func test_hasOrganizations_whenOwnershipIncludesNonPersonal_returnsTrue() throws {
        let cipher = CipherView.fixture()
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.ownershipOptions = [CipherOwner.organization(id: "org123", name: "Organization")]

        XCTAssertTrue(state.hasOrganizations)
    }

    /// `hasOrganizations` is false when ownership options is empty (not yet fetched) and organizationId is nil.
    func test_hasOrganizations_withEmptyOwnershiptOptionsAndOrgIdIsNil_returnsFalse() throws {
        let cipher = CipherView.fixture()
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.ownershipOptions = []

        XCTAssertFalse(state.hasOrganizations)
    }

    /// `getter:icon` returns the icon for a card cipher with a known brand.
    func test_icon_cardKnownBrand() throws {
        let cipher = CipherView.cardFixture(card: .fixture(brand: "Visa"))
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, Asset.Images.Cards.visa.name)
    }

    /// `getter:icon` returns the icon for a card cipher with "other" brand.
    func test_icon_cardOtherBrand() throws {
        let cipher = CipherView.cardFixture(card: .fixture(brand: "Other"))
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, Asset.Images.card24.name)
    }

    /// `getter:icon` returns the icon for a card cipher with no brand.
    func test_icon_cardNoBrand() throws {
        let cipher = CipherView.cardFixture(card: .fixture())
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, Asset.Images.card24.name)
    }

    /// `getter:icon` returns the icon for an identity cipher.
    func test_icon_identity() throws {
        let cipher = CipherView.fixture(type: .identity)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, Asset.Images.idCard24.name)
    }

    /// `getter:icon` returns the icon for a login cipher.
    func test_icon_login() throws {
        let cipher = CipherView.loginFixture(login: .fixture())
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, Asset.Images.globe24.name)
    }

    /// `getter:icon` returns the icon for a secure note cipher.
    func test_icon_secureNote() throws {
        let cipher = CipherView.fixture(type: .secureNote)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, Asset.Images.stickyNote24.name)
    }

    /// `getter:icon` returns the icon for a SSH key cipher.
    func test_icon_sshKey() throws {
        let cipher = CipherView.fixture(type: .sshKey)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, Asset.Images.key24.name)
    }

    /// `getter:iconAccessibilityId` returns the icon accessibility id.
    func test_iconAccessibilityId() throws {
        let cipher = CipherView.fixture()
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.iconAccessibilityId, "CipherIcon")
    }

    /// `getter:loginView` returns login of the cipher.
    func test_loginView() throws {
        let login = BitwardenSdk.LoginView.fixture(username: "1")
        let cipher = CipherView.loginFixture(login: login)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.loginView, login)
    }

    /// `navigationTitle` returns the navigation title for the view based on the cipher type being edited.
    func test_navigationTitle_editItem() throws {
        let subjectCard = try XCTUnwrap(CipherItemState(existing: .fixture(type: .card), hasPremium: false))
        XCTAssertEqual(subjectCard.navigationTitle, Localizations.editCard)

        let subjectIdentity = try XCTUnwrap(CipherItemState(existing: .fixture(type: .identity), hasPremium: false))
        XCTAssertEqual(subjectIdentity.navigationTitle, Localizations.editIdentity)

        let subjectLogin = try XCTUnwrap(CipherItemState(existing: .fixture(type: .login), hasPremium: false))
        XCTAssertEqual(subjectLogin.navigationTitle, Localizations.editLogin)

        let subjectSecureNote = try XCTUnwrap(CipherItemState(existing: .fixture(type: .secureNote), hasPremium: false))
        XCTAssertEqual(subjectSecureNote.navigationTitle, Localizations.editNote)

        let subjectSSHKey = try XCTUnwrap(CipherItemState(existing: .fixture(type: .sshKey), hasPremium: false))
        XCTAssertEqual(subjectSSHKey.navigationTitle, Localizations.editSSHKey)
    }

    /// `navigationTitle` returns the navigation title for the view based on the cipher type being added.
    func test_navigationTitle_newItem() {
        let subjectCard = CipherItemState(addItem: .card, hasPremium: false)
        XCTAssertEqual(subjectCard.navigationTitle, Localizations.newCard)

        let subjectIdentity = CipherItemState(addItem: .identity, hasPremium: false)
        XCTAssertEqual(subjectIdentity.navigationTitle, Localizations.newIdentity)

        let subjectLogin = CipherItemState(addItem: .login, hasPremium: false)
        XCTAssertEqual(subjectLogin.navigationTitle, Localizations.newLogin)

        let subjectSecureNote = CipherItemState(addItem: .secureNote, hasPremium: false)
        XCTAssertEqual(subjectSecureNote.navigationTitle, Localizations.newNote)

        let subjectSSHKey = CipherItemState(addItem: .sshKey, hasPremium: false)
        XCTAssertEqual(subjectSSHKey.navigationTitle, Localizations.newSSHKey)
    }

    /// `shouldShowLearnNewLoginActionCard` should be `true`, if the cipher is a login type and configuration is `.add`.
    func test_shouldShowLearnNewLoginActionCard_true() {
        let cipher = CipherView.loginFixture(login: .fixture(fido2Credentials: [.fixture()]))
        var state = CipherItemState(cloneItem: cipher, hasPremium: true)
        state.isLearnNewLoginActionCardEligible = true
        XCTAssertTrue(state.shouldShowLearnNewLoginActionCard)
    }

    /// `shouldShowLearnNewLoginActionCard` should be `false`, if the cipher is not a login type.
    func test_shouldShowLearnNewLoginActionCard_false() {
        let cipher = CipherView.cardFixture(card: .fixture(
            code: "123",
            number: "123456789"
        ))
        var state = CipherItemState(cloneItem: cipher, hasPremium: true)
        state.isLearnNewLoginActionCardEligible = true
        XCTAssertFalse(state.shouldShowLearnNewLoginActionCard)
    }

    /// `shouldShowLearnNewLoginActionCard` should be `false`, if the configuration is not `.add`.
    func test_shouldShowLearnNewLoginActionCard_false_config() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            login: .fixture()
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.isLearnNewLoginActionCardEligible = true
        XCTAssertFalse(state.shouldShowLearnNewLoginActionCard)
    }

    /// `shouldShowLearnNewLoginActionCard` should be `false`,
    /// if `.isLearnNewLoginActionCardEligible` is false.
    func test_shouldShowLearnNewLoginActionCard_false_isLearnNewLoginActionCardEligible() throws {
        let cipher = CipherView.loginFixture(login: .fixture(fido2Credentials: [.fixture()]))
        var state = CipherItemState(cloneItem: cipher, hasPremium: true)
        state.isLearnNewLoginActionCardEligible = false
        XCTAssertFalse(state.shouldShowLearnNewLoginActionCard)
    }
}
