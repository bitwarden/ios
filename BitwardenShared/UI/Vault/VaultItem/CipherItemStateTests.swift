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

    /// `getter:belongsToMultipleCollections` returns `false` when cipher belongs to no collections.
    func test_belongsToMultipleCollections_empty() throws {
        let cipher = CipherView.fixture(collectionIds: [])
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertFalse(state.belongsToMultipleCollections)
    }

    /// `getter:belongsToMultipleCollections` returns `false` when cipher belongs to one collection.
    func test_belongsToMultipleCollections_one() throws {
        let cipher = CipherView.fixture(collectionIds: ["1"])
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertFalse(state.belongsToMultipleCollections)
    }

    /// `getter:belongsToMultipleCollections` returns `true` when cipher belongs to two collections.
    func test_belongsToMultipleCollections_true() throws {
        let cipher = CipherView.fixture(collectionIds: ["1", "2"])
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.belongsToMultipleCollections)
    }

    /// `canBeDeleted` is true
    /// if the cipher does not belong to a collection
    func test_canBeDeleted_notCollection() throws {
        let cipher = CipherView.loginFixture(login: .fixture())
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.canBeDeleted)

        state.collections = [CollectionView.fixture()]
        XCTAssertTrue(state.canBeDeleted)
    }

    /// `canBeDeleted` is true
    ///  if the cipher belongs to a collection
    ///  and the user has manage permissions for that collection
    func test_canBeDeleted_canManageOneCollection() throws {
        let cipher = CipherView.loginFixture(collectionIds: ["1"], login: .fixture())
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.collections = [CollectionView.fixture(id: "1", manage: true)]
        XCTAssertTrue(state.canBeDeleted)
    }

    /// `canBeDeleted` is false
    /// if the cipher belongs to a collection
    /// and the user does not have manage permissions for that collection
    func test_canBeDeleted_cannotManageOneCollection() throws {
        let cipher = CipherView.loginFixture(collectionIds: ["1"], login: .fixture())
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.collections = [CollectionView.fixture(id: "1", manage: false)]
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
        state.collections = [
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
        state.collections = [
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
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.restrictCipherItemDeletionFlagEnabled = true
        XCTAssertFalse(state.canBeDeleted)
    }

    /// `canBeRestoredPermission` cipher permissions is nil fallback to isSoftDeleted
    func test_canBeRestoredPermission_permissions_nil() throws {
        var cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            deletedDate: nil,
            login: .fixture(),
            permissions: nil
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.restrictCipherItemDeletionFlagEnabled = true
        XCTAssertFalse(state.canBeRestoredPermission)

        cipher = CipherView.loginFixture(
            collectionIds: ["1", "2"],
            deletedDate: Date(),
            login: .fixture(),
            permissions: nil
        )
        state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertTrue(state.canBeRestoredPermission)
    }

    /// `canBeRestoredPermission` returns value from cipher permissions if not nil
    /// restore value true
    func test_canBeRestoredPermission_true() throws {
        let cipher = CipherView.loginFixture(
            deletedDate: Date(),
            login: .fixture(),
            permissions: CipherPermissions(
                delete: true,
                restore: true
            )
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.restrictCipherItemDeletionFlagEnabled = true
        XCTAssertTrue(state.canBeRestoredPermission)
    }

    /// `canBeRestoredPermission` returns value from cipher permissions if not nil
    /// restore value false
    func test_canBeRestoredPermission_false() throws {
        let cipher = CipherView.loginFixture(
            deletedDate: Date(),
            login: .fixture(),
            permissions: CipherPermissions(
                delete: true,
                restore: false
            )
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.restrictCipherItemDeletionFlagEnabled = true
        XCTAssertFalse(state.canBeRestoredPermission)
    }

    /// `restrictCipherItemDeletionFlagEnable` default value is false
    func test_restrictCipherItemDeletionFlagValue() throws {
        let cipher = CipherView.loginFixture(
            login: .fixture(),
            permissions: CipherPermissions(
                delete: false,
                restore: true
            )
        )

        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertFalse(state.restrictCipherItemDeletionFlagEnabled)
        state.restrictCipherItemDeletionFlagEnabled = true
        XCTAssertTrue(state.restrictCipherItemDeletionFlagEnabled)
    }

    /// `collectionsForOwner` contains collections that are not read-only
    func test_collectionsForOwner() throws {
        let cipher = CipherView.loginFixture(
            collectionIds: ["1", "2", "3"],
            login: .fixture(),
            organizationId: "Org1"
        )
        var state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        state.ownershipOptions = [.organization(id: "Org1", name: "Organization 1")]
        state.collections = [
            CollectionView.fixture(id: "1", organizationId: "Org1", manage: true, readOnly: false),
            CollectionView.fixture(id: "2", organizationId: "Org1", manage: false, readOnly: false),
            CollectionView.fixture(id: "3", organizationId: "Org1", manage: false, readOnly: true),
        ]
        XCTAssertEqual(state.collectionsForOwner.map(\.id), ["1", "2"])
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

    /// `getter:isShowingMultipleCollections` `true` when showing multiple collections.
    func test_isShowingMultipleCollections() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        state.cipherCollectionsToDisplay = [.fixture(), .fixture()]
        XCTAssertTrue(state.isShowingMultipleCollections)
    }

    /// `getter:isShowingMultipleCollections` `false` when showing 1 collection.
    func test_isShowingMultipleCollections_one() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        state.cipherCollectionsToDisplay = [.fixture()]
        XCTAssertFalse(state.isShowingMultipleCollections)
    }

    /// `getter:isShowingMultipleCollections` `false` when not showing collections.
    func test_isShowingMultipleCollections_empty() throws {
        let state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        XCTAssertFalse(state.isShowingMultipleCollections)
    }

    /// `getter:loginView` returns login of the cipher.
    func test_loginView() throws {
        let login = BitwardenSdk.LoginView.fixture(username: "1")
        let cipher = CipherView.loginFixture(login: login)
        let state = try XCTUnwrap(CipherItemState(existing: cipher, hasPremium: true))
        XCTAssertEqual(state.loginView, login)
    }

    /// `getter:multipleCollectionsDisplayButtonTitle` returns "Show more" when 1 collection is shown.
    func test_multipleCollectionsDisplayButtonTitle_one() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        state.cipherCollectionsToDisplay = [.fixture()]
        XCTAssertEqual(state.multipleCollectionsDisplayButtonTitle, Localizations.showMore)
    }

    /// `getter:multipleCollectionsDisplayButtonTitle` returns "Show less" when multiple collections are shown.
    func test_multipleCollectionsDisplayButtonTitle_multiple() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        state.cipherCollectionsToDisplay = [.fixture(), .fixture()]
        XCTAssertEqual(state.multipleCollectionsDisplayButtonTitle, Localizations.showLess)
    }

    /// `getter:multipleCollectionsDisplayButtonTitle` returns "" when no collections are shown.
    func test_multipleCollectionsDisplayButtonTitle_empty() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        state.cipherCollectionsToDisplay = []
        XCTAssertEqual(state.multipleCollectionsDisplayButtonTitle, "")
    }

    /// `getter:shouldDisplayFolder` returns `true` when there's a folder and doesn't belong to multiple collections.
    func test_shouldDisplayFolder_trueFolderNoMultipleCollections() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        state.folderName = "Folder"
        XCTAssertTrue(state.shouldDisplayFolder)
    }

    /// `getter:shouldDisplayFolder` returns `true` when there's a folder, belongs to multiple collections
    /// and is showing them.
    func test_shouldDisplayFolder_trueFolderMultipleCollectionsShowing() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(collectionIds: ["1", "2"]), hasPremium: true))
        state.cipherCollectionsToDisplay = [.fixture(), .fixture()]
        state.folderName = "Folder"
        XCTAssertTrue(state.shouldDisplayFolder)
    }

    /// `getter:shouldDisplayFolder` returns `false` when folder is `nil`.
    func test_shouldDisplayFolder_falseNil() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        state.folderName = nil
        XCTAssertFalse(state.shouldDisplayFolder)
    }

    /// `getter:shouldDisplayFolder` returns `false` when folder is empty.
    func test_shouldDisplayFolder_falseEmptyFolder() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        state.folderName = ""
        XCTAssertFalse(state.shouldDisplayFolder)
    }

    /// `getter:shouldDisplayFolder` returns `false` when there's a folder, belongs to multiple collections
    /// and is not showing them.
    func test_shouldDisplayFolder_falseBelongsMultipleCollectionNotShowing() throws {
        var state = try XCTUnwrap(CipherItemState(existing: .fixture(collectionIds: ["1", "2"]), hasPremium: true))
        state.cipherCollectionsToDisplay = [.fixture()]
        state.folderName = "Folder"
        XCTAssertFalse(state.shouldDisplayFolder)
    }

    /// `getter:shouldDisplayNoFolder` returns `true` when there's no organization, no folder and no collections.
    func test_shouldDisplayNoFolder_true() throws {
        let state = try XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: true))
        XCTAssertTrue(state.shouldDisplayNoFolder)
    }

    /// `getter:shouldDisplayNoFolder` returns `false` when cipher belongs to an organization.
    func test_shouldDisplayNoFolder_falseOrganization() throws {
        let state = try XCTUnwrap(CipherItemState(existing: .fixture(organizationId: "1"), hasPremium: true))
        XCTAssertFalse(state.shouldDisplayNoFolder)
    }

    /// `getter:shouldDisplayNoFolder` returns `false` when cipher belongs to a folder.
    func test_shouldDisplayNoFolder_falseFolder() throws {
        let state = try XCTUnwrap(CipherItemState(existing: .fixture(folderId: "1"), hasPremium: true))
        XCTAssertFalse(state.shouldDisplayNoFolder)
    }

    /// `getter:shouldDisplayNoFolder` returns `false` when cipher belongs to a collection.
    func test_shouldDisplayNoFolder_falseCollections() throws {
        let state = try XCTUnwrap(CipherItemState(existing: .fixture(collectionIds: ["1"]), hasPremium: true))
        XCTAssertFalse(state.shouldDisplayNoFolder)
    }

    /// `getter:shouldDisplayNoFolder` returns `false` when cipher belongs to an organization, a folder
    /// and a collection.
    func test_shouldDisplayNoFolder_falseBelongsAll() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    collectionIds: ["1"],
                    folderId: "2",
                    organizationId: "3"
                ),
                hasPremium: true
            )
        )
        XCTAssertFalse(state.shouldDisplayNoFolder)
    }

    /// `getter:shouldUseCustomPlaceholderContent` returns `false` when cipher is card and its brand is not `.other`.
    func test_shouldUseCustomPlaceholderContent_false() throws {
        let brandValues = CardComponent.Brand.allCases.filter { $0 != .other }
        for brand in brandValues {
            let state = try XCTUnwrap(
                CipherItemState(
                    existing: .fixture(
                        card: .fixture(brand: brand.rawValue),
                        type: .card
                    ),
                    hasPremium: true
                )
            )
            XCTAssertFalse(state.shouldUseCustomPlaceholderContent)
        }
    }

    /// `getter:shouldUseCustomPlaceholderContent` returns `true` when cipher is card and its brand is `.other`.
    func test_shouldUseCustomPlaceholderContent_trueBrandOther() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    card: .fixture(brand: "Other"),
                    type: .card
                ),
                hasPremium: true
            )
        )
        XCTAssertTrue(state.shouldUseCustomPlaceholderContent)
    }

    /// `getter:shouldUseCustomPlaceholderContent` returns `true` when cipher is card and its brand is not defined.
    func test_shouldUseCustomPlaceholderContent_trueNoBrand() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    card: .fixture(brand: nil),
                    type: .card
                ),
                hasPremium: true
            )
        )
        XCTAssertTrue(state.shouldUseCustomPlaceholderContent)
    }

    /// `getter:shouldUseCustomPlaceholderContent` returns `true` when cipher is card and its brand
    /// can't be converted to a `CardComponent.Brand`.
    func test_shouldUseCustomPlaceholderContent_trueSomethingNotABrand() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    card: .fixture(brand: "something-that-is-not-a-card-brand"),
                    type: .card
                ),
                hasPremium: true
            )
        )
        XCTAssertTrue(state.shouldUseCustomPlaceholderContent)
    }

    /// `getter:shouldUseCustomPlaceholderContent` returns `true` when cipher is not a card
    func test_shouldUseCustomPlaceholderContent_trueNotACard() throws {
        let types: [BitwardenSdk.CipherType] = [.identity, .login, .secureNote, .sshKey]
        for type in types {
            let state = try XCTUnwrap(
                CipherItemState(
                    existing: .fixture(
                        type: type
                    ),
                    hasPremium: true
                )
            )
            XCTAssertTrue(state.shouldUseCustomPlaceholderContent)
        }
    }

    /// `getter:totalHeaderAdditionalItems` returns 0 when cipher doesn't belong to an organzation.
    func test_totalHeaderAdditionalItems_noOrganization() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(),
                hasPremium: true
            )
        )
        XCTAssertEqual(state.totalHeaderAdditionalItems, 0)
    }

    /// `getter:totalHeaderAdditionalItems` returns 1 when cipher belongs to an organzation
    /// but not to collections nor folder.
    func test_totalHeaderAdditionalItems_organizationButNoCollectionNoFolder() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(organizationId: "1"),
                hasPremium: true
            )
        )
        XCTAssertEqual(state.totalHeaderAdditionalItems, 1)
    }

    /// `getter:totalHeaderAdditionalItems` returns 4 when cipher belongs to an organzation
    /// and to 3 collections but not to a folder.
    func test_totalHeaderAdditionalItems_organizationCollectionsNoFolder() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(collectionIds: ["1", "2", "3"], organizationId: "1"),
                hasPremium: true
            )
        )
        XCTAssertEqual(state.totalHeaderAdditionalItems, 4)
    }

    /// `getter:totalHeaderAdditionalItems` returns 5 when cipher belongs to an organzation,
    /// to 3 collections and a folder.
    func test_totalHeaderAdditionalItems_organizationCollectionsFolder() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    collectionIds: ["1", "2", "3"],
                    folderId: "4",
                    organizationId: "1"
                ),
                hasPremium: true
            )
        )
        XCTAssertEqual(state.totalHeaderAdditionalItems, 5)
    }

    /// `getter:totalHeaderAdditionalItems` returns 2 when cipher belongs to an organzation,
    /// no collections and a folder.
    func test_totalHeaderAdditionalItems_organizationFolderAndNoCollections() throws {
        let state = try XCTUnwrap(
            CipherItemState(
                existing: .fixture(
                    folderId: "4",
                    organizationId: "1"
                ),
                hasPremium: true
            )
        )
        XCTAssertEqual(state.totalHeaderAdditionalItems, 2)
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
