import BitwardenResources
import BitwardenSdk
import Foundation
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

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
    /// have Premium and the organization doesn't use TOTP.
    func test_init_existing_isTOTPAvailable_notAvailable() throws {
        let cipher = CipherView.loginFixture(login: .fixture())
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false))
        XCTAssertFalse(state.loginState.isTOTPAvailable)
    }

    /// `init(existing:hasPremium:)` sets `loginState.isTOTPAvailable` to true if the user has Premium.
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

    /// `archiveInfoText` returns nil when the item is not archived.
    func test_archiveInfoText_notArchived() throws {
        let state = try CipherItemState.initForArchive(archivedDate: nil)
        XCTAssertEqual(state.archiveInfoText, "")
    }

    /// `archiveInfoText` returns nil when the item is deleted.
    func test_archiveInfoText_deleted() throws {
        let state = try CipherItemState.initForArchive(
            archivedDate: .now,
            deletedDate: .now,
        )
        XCTAssertEqual(state.archiveInfoText, "")
    }

    /// `archiveInfoText` returns the Premium text when the item is archived and user has Premium.
    func test_archiveInfoText_archivedWithPremium() throws {
        let state = try CipherItemState.initForArchive(
            archivedDate: .now,
            hasPremium: true,
        )
        XCTAssertEqual(state.archiveInfoText, Localizations.thisItemIsArchived)
    }

    /// `archiveInfoText` returns the non-Premium text when the item is archived and user lacks Premium.
    func test_archiveInfoText_archivedWithoutPremium() throws {
        let state = try CipherItemState.initForArchive(
            archivedDate: .now,
            hasPremium: false,
        )
        XCTAssertEqual(
            state.archiveInfoText,
            Localizations.thisItemIsArchivedSavingChangesWillRestoreItToYourVault,
        )
    }

    /// `canAssignToCollection` returns false if the user doesn't have access to any organizations.
    func test_canAssignToCollection_noOrganizations() throws {
        let cipher = CipherView.fixture(organizationId: nil)
        var subject = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false))
        subject.ownershipOptions = [.personal(email: "user@bitwarden.com")]
        XCTAssertFalse(subject.canAssignToCollection)
    }

    /// `canAssignToCollection` returns false if the user is in an organization but the cipher is
    /// still in a personal vault.
    func test_canAssignToCollection_organizationsAvailable() throws {
        let cipher = CipherView.fixture(organizationId: nil)
        var subject = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false))
        subject.ownershipOptions = [
            .personal(email: "user@bitwarden.com"),
            .organization(id: "1", name: "Test Organization"),
        ]
        XCTAssertFalse(subject.canAssignToCollection)
    }

    /// `canAssignToCollection` returns true if the user is in an organization and the cipher is in
    /// the organization's vault.
    func test_canAssignToCollection_organizationCipher() throws {
        let cipher = CipherView.fixture(organizationId: "1")
        var subject = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false))
        subject.ownershipOptions = [
            .personal(email: "user@bitwarden.com"),
            .organization(id: "1", name: "Test Organization"),
        ]
        XCTAssertTrue(subject.canAssignToCollection)
    }

    /// `canBeArchived` is `true` if the cipher is not already archived or deleted.
    func test_canBeArchived() throws {
        XCTAssertTrue(
            try CipherItemState.initForArchive(archivedDate: nil).canBeArchived,
        )
        XCTAssertTrue(
            try CipherItemState.initForArchive(archivedDate: nil, hasPremium: false).canBeArchived,
        )
        XCTAssertFalse(
            try CipherItemState.initForArchive(archivedDate: .now).canBeArchived,
        )
        XCTAssertFalse(
            try CipherItemState.initForArchive(archivedDate: nil, deletedDate: .now).canBeArchived,
        )
        XCTAssertFalse(
            try CipherItemState.initForArchive(archivedDate: .now, deletedDate: .now).canBeArchived,
        )
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
            login: .fixture(),
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
            login: .fixture(),
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
                restore: true,
            ),
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
                restore: true,
            ),
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
            permissions: nil,
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertFalse(state.canBeRestored)

        cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            deletedDate: Date(),
            login: .fixture(),
            permissions: nil,
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
                restore: true,
            ),
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
                restore: false,
            ),
        )
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertFalse(state.canBeRestored)
    }

    /// `canBeUnarchived` returns `true` when the cipher has an archived date.
    func test_canBeUnarchived() throws {
        XCTAssertTrue(
            try CipherItemState.initForArchive(archivedDate: .now).canBeUnarchived,
        )
        XCTAssertFalse(
            try CipherItemState.initForArchive(archivedDate: nil).canBeUnarchived,
        )
        XCTAssertFalse(
            try CipherItemState.initForArchive(archivedDate: .now, deletedDate: .now).canBeUnarchived,
        )
    }

    /// `canMoveToOrganization` returns false if the cipher is in an existing organization.
    func test_canMoveToOrganization_cipherInExistingOrganization() throws {
        let cipher = CipherView.fixture(organizationId: "1")
        var subject = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false))
        subject.ownershipOptions = [
            .personal(email: "user@bitwarden.com"),
            .organization(id: "1", name: "Test Organization"),
        ]
        XCTAssertFalse(subject.canMoveToOrganization)
    }

    /// `canMoveToOrganization` returns false if the user doesn't have access to any organizations.
    func test_canMoveToOrganization_noOrganizations() throws {
        let cipher = CipherView.fixture(organizationId: nil)
        var subject = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false))
        subject.ownershipOptions = [.personal(email: "user@bitwarden.com")]
        XCTAssertFalse(subject.canMoveToOrganization)
    }

    /// `canMoveToOrganization` returns true if the cipher isn't in an organization and the user has
    /// access to one or more organizations.
    func test_canMoveToOrganization_organizationsAvailable() throws {
        let cipher = CipherView.fixture(organizationId: nil)
        var subject = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: false))
        subject.ownershipOptions = [
            .personal(email: "user@bitwarden.com"),
            .organization(id: "1", name: "Test Organization"),
        ]
        XCTAssertTrue(subject.canMoveToOrganization)
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

    /// `getter:icon` returns the icon for a bank account cipher.
    func test_icon_bankAccount() throws {
        let cipher = CipherView.fixture(type: .bankAccount)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, SharedAsset.Icons.bankAccount24.name)
    }

    /// `getter:icon` returns the icon for a card cipher with a known brand.
    func test_icon_cardKnownBrand() throws {
        let cipher = CipherView.cardFixture(card: .fixture(brand: "Visa"))
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, SharedAsset.Icons.Cards.visa.name)
    }

    /// `getter:icon` returns the icon for a card cipher with "other" brand.
    func test_icon_cardOtherBrand() throws {
        let cipher = CipherView.cardFixture(card: .fixture(brand: "Other"))
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, SharedAsset.Icons.card24.name)
    }

    /// `getter:icon` returns the icon for a card cipher with no brand.
    func test_icon_cardNoBrand() throws {
        let cipher = CipherView.cardFixture(card: .fixture())
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, SharedAsset.Icons.card24.name)
    }

    /// `getter:icon` returns the icon for a driver's license cipher.
    func test_icon_driversLicense() throws {
        let cipher = CipherView.fixture(type: .driversLicense)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, SharedAsset.Icons.idCard24.name)
    }

    /// `getter:icon` returns the icon for an identity cipher.
    func test_icon_identity() throws {
        let cipher = CipherView.fixture(type: .identity)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, SharedAsset.Icons.idCard24.name)
    }

    /// `getter:icon` returns the icon for a login cipher.
    func test_icon_login() throws {
        let cipher = CipherView.loginFixture(login: .fixture())
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, SharedAsset.Icons.globe24.name)
    }

    /// `getter:icon` returns the icon for a passport cipher.
    func test_icon_passport() throws {
        let cipher = CipherView.fixture(type: .passport)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, SharedAsset.Icons.idCard24.name)
    }

    /// `getter:icon` returns the icon for a secure note cipher.
    func test_icon_secureNote() throws {
        let cipher = CipherView.fixture(type: .secureNote)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, SharedAsset.Icons.stickyNote24.name)
    }

    /// `getter:icon` returns the icon for a SSH key cipher.
    func test_icon_sshKey() throws {
        let cipher = CipherView.fixture(type: .sshKey)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.icon.name, SharedAsset.Icons.key24.name)
    }

    /// `getter:iconAccessibilityId` returns the icon accessibility id.
    func test_iconAccessibilityId() throws {
        let cipher = CipherView.fixture()
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.iconAccessibilityId, "CipherIcon")
    }

    /// `isArchived` is `true` if the cipher is not already archived or deleted.
    func test_isArchived() throws {
        XCTAssertFalse(
            try XCTUnwrap(CipherItemState(
                existing: CipherView.loginFixture(login: .fixture()),
                hasPremium: true,
            )).isArchived,
        )
        XCTAssertTrue(
            try CipherItemState.initForArchive(archivedDate: .now).isArchived,
        )
        XCTAssertFalse(
            try CipherItemState.initForArchive(archivedDate: nil, deletedDate: .now).isArchived,
        )
        XCTAssertFalse(
            try CipherItemState.initForArchive(archivedDate: .now, deletedDate: .now).isArchived,
        )
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
        XCTAssertEqual(subjectCard.navigationTitle, Localizations.addCard)

        let subjectIdentity = CipherItemState(addItem: .identity, hasPremium: false)
        XCTAssertEqual(subjectIdentity.navigationTitle, Localizations.addIdentity)

        let subjectLogin = CipherItemState(addItem: .login, hasPremium: false)
        XCTAssertEqual(subjectLogin.navigationTitle, Localizations.addLogin)

        let subjectSecureNote = CipherItemState(addItem: .secureNote, hasPremium: false)
        XCTAssertEqual(subjectSecureNote.navigationTitle, Localizations.addNote)

        let subjectSSHKey = CipherItemState(addItem: .sshKey, hasPremium: false)
        XCTAssertEqual(subjectSSHKey.navigationTitle, Localizations.addSSHKey)
    }

    /// `setter:owner` adds the default user collection to the collection IDs
    /// when it's adding, there's a default user collection for the owner organization and such
    /// organization has the `.personalOwnership` policy turned on.
    func test_owner_addsDefaultCollection() {
        var subject = CipherItemState(hasPremium: false)
        subject.organizationId = "2"
        subject.ownershipOptions = [
            .organization(id: "1", name: "Org"),
            .organization(id: "2", name: "Org2"),
            .organization(id: "3", name: "Org3"),
        ]
        subject.allUserCollections = [
            .fixture(id: "1", organizationId: "1", type: .defaultUserCollection),
            .fixture(id: "2", organizationId: "1"),
            .fixture(id: "3", organizationId: "2"),
            .fixture(id: "4", organizationId: "2", type: .defaultUserCollection),
        ]
        subject.organizationsWithPersonalOwnershipPolicy = ["1", "2"]
        subject.collectionIds = []

        subject.owner = .organization(id: "1", name: "Org")
        XCTAssertEqual(subject.collectionIds, ["1"])
    }

    /// `selectDefaultCollectionIfNeeded()` adds the default user collection to the collection IDs
    /// when it's adding, there's a default user collection for the owner organization and such
    /// organization has the `.personalOwnership` policy turned on.
    func test_selectDefaultCollectionIfNeeded_addsDefaultCollection() {
        var subject = CipherItemState(hasPremium: false)
        subject.organizationId = "1"
        subject.ownershipOptions = [
            .organization(id: "1", name: "Org"),
            .organization(id: "2", name: "Org2"),
            .organization(id: "3", name: "Org3"),
        ]
        subject.allUserCollections = [
            .fixture(id: "1", organizationId: "1", type: .defaultUserCollection),
            .fixture(id: "2", organizationId: "1"),
            .fixture(id: "3", organizationId: "2"),
            .fixture(id: "4", organizationId: "2", type: .defaultUserCollection),
        ]
        subject.organizationsWithPersonalOwnershipPolicy = ["1", "2"]
        subject.collectionIds = []

        subject.selectDefaultCollectionIfNeeded()
        XCTAssertEqual(subject.collectionIds, ["1"])

        // added this to check that the collection doesn't get duplicated
        // when the function is called twice.
        subject.selectDefaultCollectionIfNeeded()
        XCTAssertEqual(subject.collectionIds, ["1"])
    }

    /// `selectDefaultCollectionIfNeeded()` doesn't add the default user collection to the collection IDs
    /// when it's editing.
    func test_selectDefaultCollectionIfNeeded_editing() throws {
        var subject = try XCTUnwrap(CipherItemState(existing: .fixture(id: "1"), hasPremium: false))
        subject.organizationId = "1"
        subject.ownershipOptions = [
            .organization(id: "1", name: "Org"),
            .organization(id: "2", name: "Org2"),
            .organization(id: "3", name: "Org3"),
        ]
        subject.allUserCollections = [
            .fixture(id: "1", organizationId: "1", type: .defaultUserCollection),
            .fixture(id: "2", organizationId: "1"),
            .fixture(id: "3", organizationId: "2"),
            .fixture(id: "4", organizationId: "2", type: .defaultUserCollection),
        ]
        subject.organizationsWithPersonalOwnershipPolicy = ["1", "2"]
        subject.collectionIds = []

        subject.selectDefaultCollectionIfNeeded()
        XCTAssertEqual(subject.collectionIds, [])
    }

    /// `selectDefaultCollectionIfNeeded()` doesn't add the default user collection to the collection IDs
    /// when it's adding, but there's no default user collection for the owner organization.
    func test_selectDefaultCollectionIfNeeded_noDefaultCollection() {
        var subject = CipherItemState(hasPremium: false)
        subject.organizationId = "1"
        subject.ownershipOptions = [
            .organization(id: "1", name: "Org"),
            .organization(id: "2", name: "Org2"),
            .organization(id: "3", name: "Org3"),
        ]
        subject.allUserCollections = [
            .fixture(id: "1", organizationId: "1"),
            .fixture(id: "2", organizationId: "1"),
            .fixture(id: "3", organizationId: "2"),
            .fixture(id: "4", organizationId: "2", type: .defaultUserCollection),
        ]
        subject.organizationsWithPersonalOwnershipPolicy = ["1", "2"]
        subject.collectionIds = []

        subject.selectDefaultCollectionIfNeeded()
        XCTAssertEqual(subject.collectionIds, [])
    }

    /// `selectDefaultCollectionIfNeeded()` doesn't add the default user collection to the collection IDs
    /// when it's adding, there's  default user collection for the owner organization and such
    /// organization has the `.personalOwnership` policy turned off.
    func test_selectDefaultCollectionIfNeeded_personalOwnershipOff() {
        var subject = CipherItemState(hasPremium: false)
        subject.organizationId = "1"
        subject.ownershipOptions = [
            .organization(id: "1", name: "Org"),
            .organization(id: "2", name: "Org2"),
            .organization(id: "3", name: "Org3"),
        ]
        subject.allUserCollections = [
            .fixture(id: "1", organizationId: "1", type: .defaultUserCollection),
            .fixture(id: "2", organizationId: "1"),
            .fixture(id: "3", organizationId: "2"),
            .fixture(id: "4", organizationId: "2", type: .defaultUserCollection),
        ]
        subject.organizationsWithPersonalOwnershipPolicy = ["2"]
        subject.collectionIds = []

        subject.selectDefaultCollectionIfNeeded()
        XCTAssertEqual(subject.collectionIds, [])
    }

    /// `shouldDisplayAsArchived` returns `true` when the feature flag is enabled and cipher can be unarchived.
    func test_shouldDisplayAsArchived_true() throws {
        XCTAssertTrue(
            try CipherItemState.initForArchive(archivedDate: .now).shouldDisplayAsArchived,
        )
    }

    /// `shouldDisplayAsArchived` returns `false` when the cipher is not archived.
    func test_shouldDisplayAsArchived_false_notArchived() throws {
        XCTAssertFalse(
            try CipherItemState.initForArchive(archivedDate: nil).shouldDisplayAsArchived,
        )
    }

    /// `shouldDisplayAsArchived` returns `false` when the cipher is deleted.
    func test_shouldDisplayAsArchived_false_deleted() throws {
        XCTAssertFalse(
            try CipherItemState.initForArchive(
                archivedDate: .now,
                deletedDate: .now,
            ).shouldDisplayAsArchived,
        )
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
            number: "123456789",
        ))
        var state = CipherItemState(cloneItem: cipher, hasPremium: true)
        state.isLearnNewLoginActionCardEligible = true
        XCTAssertFalse(state.shouldShowLearnNewLoginActionCard)
    }

    /// `shouldShowLearnNewLoginActionCard` should be `false`, if the configuration is not `.add`.
    func test_shouldShowLearnNewLoginActionCard_false_config() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            login: .fixture(),
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

    /// `update(from:)` updates the state from an updated card `CipherView`.
    func test_updateFromCipherView_card() {
        var subject = CipherItemState(existing: .fixture(type: .card), hasPremium: true)
        let updatedCipher = CipherView.fixture(
            card: .fixture(cardholderName: "Bitwarden User", code: "123", number: "1111222233334444"),
            id: "123",
            name: "Card",
            type: .card,
        )
        subject?.update(from: updatedCipher)

        let expected = CipherItemState(existing: updatedCipher, hasPremium: true)

        XCTAssertEqual(subject, expected)
    }

    /// `update(from:)` updates the state from an updated identity `CipherView`.
    func test_updateFromCipherView_identity() {
        var subject = CipherItemState(existing: .fixture(type: .identity), hasPremium: true)
        let updatedCipher = CipherView.fixture(
            id: "123",
            identity: .fixture(firstName: "First", lastName: "Last"),
            name: "Identity",
            type: .identity,
        )
        subject?.update(from: updatedCipher)

        let expected = CipherItemState(existing: updatedCipher, hasPremium: true)

        XCTAssertEqual(subject, expected)
    }

    /// `update(from:)` updates the state from an updated login `CipherView`.
    func test_updateFromCipherView_login() {
        var subject = CipherItemState(existing: .fixture(), hasPremium: true)
        let updatedCipher = CipherView.fixture(
            attachments: [.fixture()],
            collectionIds: ["collection-1", "collection-2"],
            creationDate: Date(year: 2025, month: 1, day: 1),
            favorite: true,
            folderId: "folder-1",
            id: "123",
            login: .fixture(password: "password", username: "user"),
            name: "Bitwarden",
            notes: "Secure notes",
            organizationId: "organization-1",
            revisionDate: Date(year: 2025, month: 6, day: 1),
            type: .login,
        )
        subject?.update(from: updatedCipher)

        let expected = CipherItemState(existing: updatedCipher, hasPremium: true)

        XCTAssertEqual(subject, expected)
    }

    /// `update(from:)` updates the state from an updated secure note `CipherView`.
    func test_updateFromCipherView_note() {
        var subject = CipherItemState(existing: .fixture(type: .secureNote), hasPremium: false)
        let updatedCipher = CipherView.fixture(
            id: "123",
            name: "Identity",
            notes: "Secure note text",
            type: .secureNote,
        )
        subject?.update(from: updatedCipher)

        let expected = CipherItemState(existing: updatedCipher, hasPremium: false)

        XCTAssertEqual(subject, expected)
    }

    /// `update(from:)` updates the state from an updated SSH key `CipherView`.
    func test_updateFromCipherView_sshKey() {
        var subject = CipherItemState(existing: .fixture(type: .sshKey), hasPremium: false)
        let updatedCipher = CipherView.fixture(
            id: "123",
            name: "SSH Key",
            sshKey: .fixture(),
            type: .sshKey,
        )
        subject?.update(from: updatedCipher)

        let expected = CipherItemState(existing: updatedCipher, hasPremium: false)

        XCTAssertEqual(subject, expected)
    }

    /// `update(from:preservingTOTPState:)` preserves the in-memory TOTP state regardless of
    /// whether the incoming cipher view has a TOTP key, while still updating all other login
    /// fields normally.
    func test_updateFromCipherView_TOTPState() throws {
        let totpKey = "JBSWY3DPEHPK3PXP"
        var subject = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(login: .fixture(totp: totpKey), type: .login),
                hasPremium: false,
            ),
        )
        let originalLoginState = subject.loginState

        // Cipher arrives with no TOTP key: override wins.
        let updatedCipherNoTotp = CipherView.fixture(
            id: "123",
            login: .fixture(password: "updated-password", totp: nil),
            name: "Updated Name",
            type: .login,
        )
        subject.update(from: updatedCipherNoTotp, preservingTOTPState: originalLoginState.totpState)

        XCTAssertEqual(subject.name, "Updated Name")
        XCTAssertEqual(subject.loginState.totpState, originalLoginState.totpState)
        XCTAssertEqual(subject.loginState.password, "updated-password")

        // Cipher arrives with a different TOTP key: override still wins.
        let updatedCipherWithTotp = CipherView.fixture(
            id: "123",
            login: .fixture(password: "updated-password", totp: "DIFFERENTKEY"),
            name: "Updated Name",
            type: .login,
        )
        subject.update(from: updatedCipherWithTotp, preservingTOTPState: originalLoginState.totpState)

        XCTAssertEqual(subject.loginState.totpState, originalLoginState.totpState)
    }

    /// `init(existing:hasPremium:)` populates `driversLicenseItemState` from a cipher with a
    /// driver's license, preserving all 11 fields including the raw date strings.
    func test_init_existing_driversLicense() throws {
        let cipher = CipherView.driversLicenseFixture()
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))

        XCTAssertEqual(state.driversLicenseItemState, cipher.driversLicenseItemState())
        XCTAssertEqual(state.driversLicenseItemState.firstName, "Bit")
        XCTAssertEqual(state.driversLicenseItemState.middleName, "W")
        XCTAssertEqual(state.driversLicenseItemState.lastName, "Warden")
        XCTAssertEqual(state.driversLicenseItemState.dateOfBirth, "1989-08-01")
        XCTAssertEqual(state.driversLicenseItemState.licenseNumber, "D1234567")
        XCTAssertEqual(state.driversLicenseItemState.issuingCountry, "United States")
        XCTAssertEqual(state.driversLicenseItemState.issuingState, "California")
        XCTAssertEqual(state.driversLicenseItemState.issueDate, "2019-08-01")
        XCTAssertEqual(state.driversLicenseItemState.expirationDate, "2029-08-01")
        XCTAssertEqual(state.driversLicenseItemState.issuingAuthority, "DMV")
        XCTAssertEqual(state.driversLicenseItemState.licenseClass, "C")
    }

    /// `newCipherView()` emits the `driversLicense` view only when the cipher type is
    /// `.driversLicense`, preserving all the state's fields.
    func test_newCipherView_driversLicense() {
        var subject = CipherItemState(hasPremium: true)
        subject.type = .driversLicense
        subject.driversLicenseItemState.firstName = "Bit"
        subject.driversLicenseItemState.licenseNumber = "D1234567"
        subject.driversLicenseItemState.dateOfBirth = "1989-08-01"
        subject.driversLicenseItemState.expirationDate = "2029-08-01"

        let cipher = subject.newCipherView()

        XCTAssertEqual(cipher.driversLicense?.firstName, "Bit")
        XCTAssertEqual(cipher.driversLicense?.licenseNumber, "D1234567")
        XCTAssertEqual(cipher.driversLicense?.dateOfBirth, "1989-08-01")
        XCTAssertEqual(cipher.driversLicense?.expirationDate, "2029-08-01")
    }

    /// `newCipherView()` emits a `nil` `driversLicense` view when the cipher type is not
    /// `.driversLicense`, even if driver's license state happens to be populated.
    func test_newCipherView_driversLicense_nilForOtherTypes() {
        var subject = CipherItemState(hasPremium: true)
        subject.type = .login
        subject.driversLicenseItemState.firstName = "Bit"

        let cipher = subject.newCipherView()

        XCTAssertNil(cipher.driversLicense)
    }

    /// `init(existing:hasPremium:)` populates `passportItemState` from a cipher with a passport,
    /// preserving all fields including the raw date strings.
    func test_init_existing_passport() throws {
        let cipher = CipherView.fixture(
            passport: .fixture(
                surname: "Johnson",
                givenName: "Mitchell",
                dateOfBirth: "2025-04-20",
                sex: "Male",
                birthPlace: "USA",
                nationality: "USA",
                issuingCountry: "United States",
                passportNumber: "X12345678",
                passportType: "Regular/Tourist",
                nationalIdentificationNumber: "123456789",
                issuingAuthority: "U.S. Department of State",
                issueDate: "2021-08-10",
                expirationDate: "2026-08-10",
            ),
            type: .passport,
        )
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))

        XCTAssertEqual(state.passportItemState, cipher.passportItemState())
        XCTAssertEqual(state.passportItemState.surname, "Johnson")
        XCTAssertEqual(state.passportItemState.givenName, "Mitchell")
        XCTAssertEqual(state.passportItemState.dateOfBirth, "2025-04-20")
        XCTAssertEqual(state.passportItemState.passportNumber, "X12345678")
        XCTAssertEqual(state.passportItemState.nationalIdentificationNumber, "123456789")
        XCTAssertEqual(state.passportItemState.issueDate, "2021-08-10")
        XCTAssertEqual(state.passportItemState.expirationDate, "2026-08-10")
    }

    /// `newCipherView()` emits the `passport` view only when the cipher type is `.passport`,
    /// preserving the state's fields.
    func test_newCipherView_passport() {
        var subject = CipherItemState(hasPremium: true)
        subject.type = .passport
        subject.passportItemState.surname = "Johnson"
        subject.passportItemState.passportNumber = "X12345678"
        subject.passportItemState.dateOfBirth = "2025-04-20"
        subject.passportItemState.expirationDate = "2026-08-10"

        let cipher = subject.newCipherView()

        XCTAssertEqual(cipher.passport?.surname, "Johnson")
        XCTAssertEqual(cipher.passport?.passportNumber, "X12345678")
        XCTAssertEqual(cipher.passport?.dateOfBirth, "2025-04-20")
        XCTAssertEqual(cipher.passport?.expirationDate, "2026-08-10")
    }

    /// `newCipherView()` emits a `nil` `passport` view when the cipher type is not `.passport`, even
    /// if passport state happens to be populated.
    func test_newCipherView_passport_nilForOtherTypes() {
        var subject = CipherItemState(hasPremium: true)
        subject.type = .login
        subject.passportItemState.surname = "Johnson"

        let cipher = subject.newCipherView()

        XCTAssertNil(cipher.passport)
    }

    /// `init(existing:hasPremium:)` populates `bankAccountItemState` from a cipher with a bank
    /// account, preserving all 10 fields.
    func test_init_existing_bankAccount() throws {
        let cipher = CipherView.bankAccountFixture()
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))

        XCTAssertEqual(state.bankAccountItemState, cipher.bankAccountItemState())
        XCTAssertEqual(state.bankAccountItemState.bankName, "Bank of America")
        XCTAssertEqual(state.bankAccountItemState.nameOnAccount, "Personal Checking")
        XCTAssertEqual(state.bankAccountItemState.accountType, .custom(.checking))
        XCTAssertEqual(state.bankAccountItemState.accountNumber, "1234567890123456")
        XCTAssertEqual(state.bankAccountItemState.routingNumber, "1234567890")
        XCTAssertEqual(state.bankAccountItemState.branchNumber, "100")
        XCTAssertEqual(state.bankAccountItemState.pin, "1234")
        XCTAssertEqual(state.bankAccountItemState.swiftCode, "123234")
        XCTAssertEqual(state.bankAccountItemState.iban, "23423434543")
        XCTAssertEqual(state.bankAccountItemState.bankContactPhone, "123-456-7890")
    }

    /// `newCipherView()` emits the `bankAccount` view only when the cipher type is `.bankAccount`,
    /// preserving the state's fields.
    func test_newCipherView_bankAccount() {
        var subject = CipherItemState(hasPremium: true)
        subject.type = .bankAccount
        subject.bankAccountItemState.bankName = "Bank of America"
        subject.bankAccountItemState.accountType = .custom(.checking)
        subject.bankAccountItemState.accountNumber = "1234567890123456"
        subject.bankAccountItemState.pin = "1234"

        let cipher = subject.newCipherView()

        XCTAssertEqual(cipher.bankAccount?.bankName, "Bank of America")
        XCTAssertEqual(cipher.bankAccount?.accountType, "checking")
        XCTAssertEqual(cipher.bankAccount?.accountNumber, "1234567890123456")
        XCTAssertEqual(cipher.bankAccount?.pin, "1234")
    }

    /// `newCipherView()` emits a `nil` `bankAccount` view when the cipher type is not
    /// `.bankAccount`, even if bank account state happens to be populated.
    func test_newCipherView_bankAccount_nilForOtherTypes() {
        var subject = CipherItemState(hasPremium: true)
        subject.type = .login
        subject.bankAccountItemState.bankName = "Bank of America"

        let cipher = subject.newCipherView()

        XCTAssertNil(cipher.bankAccount)
    }
}

// MARK: - CipherItemState

private extension CipherItemState {
    /// Initializes a `CipherItemState` for archive related tests.
    /// - Parameters:
    ///   - archivedDate: The archived date.
    ///   - deletedDate: The deleted date.
    ///   - hasPremium: Whether the user has Premium account.
    static func initForArchive(
        archivedDate: Date?,
        deletedDate: Date? = nil,
        hasPremium: Bool = true,
    ) throws -> CipherItemState {
        try XCTUnwrap(CipherItemState(
            existing: CipherView.loginFixture(
                archivedDate: archivedDate,
                deletedDate: deletedDate,
                login: .fixture(),
            ),
            hasPremium: hasPremium,
        ))
    }
}
