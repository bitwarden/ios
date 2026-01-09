import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - CipherListViewExtensionsTests

class CipherListViewExtensionsTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Tests

    /// `belongsToGroup(_:)` returns `true` when the cipher is archived and the group is `.archive`.
    func test_belongsToGroup_archive() {
        let cipher = CipherListView.fixture(archivedDate: .now)
        XCTAssertTrue(cipher.belongsToGroup(.archive))
        XCTAssertFalse(cipher.belongsToGroup(.trash))
        XCTAssertFalse(cipher.belongsToGroup(.identity))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is a card type and the group is `.card`.
    func test_belongsToGroup_card() {
        let cipher = CipherListView.fixture(type: .card(.fixture()))
        XCTAssertTrue(cipher.belongsToGroup(.card))
        XCTAssertFalse(cipher.belongsToGroup(.login))
        XCTAssertFalse(cipher.belongsToGroup(.identity))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is a login type and the group is `.login`.
    func test_belongsToGroup_login() {
        let cipher = CipherListView.fixture(type: .login(.fixture()))
        XCTAssertTrue(cipher.belongsToGroup(.login))
        XCTAssertFalse(cipher.belongsToGroup(.card))
        XCTAssertFalse(cipher.belongsToGroup(.identity))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is an identity type and the group is `.identity`.
    func test_belongsToGroup_identity() {
        let cipher = CipherListView.fixture(type: .identity)
        XCTAssertTrue(cipher.belongsToGroup(.identity))
        XCTAssertFalse(cipher.belongsToGroup(.card))
        XCTAssertFalse(cipher.belongsToGroup(.login))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is a secure note type and the group is `.secureNote`.
    func test_belongsToGroup_secureNote() {
        let cipher = CipherListView.fixture(type: .secureNote)
        XCTAssertTrue(cipher.belongsToGroup(.secureNote))
        XCTAssertFalse(cipher.belongsToGroup(.card))
        XCTAssertFalse(cipher.belongsToGroup(.login))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is an SSH key type and the group is `.sshKey`.
    func test_belongsToGroup_sshKey() {
        let cipher = CipherListView.fixture(type: .sshKey)
        XCTAssertTrue(cipher.belongsToGroup(.sshKey))
        XCTAssertFalse(cipher.belongsToGroup(.card))
        XCTAssertFalse(cipher.belongsToGroup(.login))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is a login with TOTP and the group is `.totp`.
    func test_belongsToGroup_totp() {
        let loginWithTotp = LoginListView.fixture(totp: "JBSWY3DPEHPK3PXP")
        let cipher = CipherListView.fixture(type: .login(loginWithTotp))
        XCTAssertTrue(cipher.belongsToGroup(.totp))
        XCTAssertTrue(cipher.belongsToGroup(.login))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher is a login without TOTP and the group is `.totp`.
    func test_belongsToGroup_totp_noTotp() {
        let loginWithoutTotp = LoginListView.fixture(totp: nil)
        let cipher = CipherListView.fixture(type: .login(loginWithoutTotp))
        XCTAssertFalse(cipher.belongsToGroup(.totp))
        XCTAssertTrue(cipher.belongsToGroup(.login))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher is not a login and the group is `.totp`.
    func test_belongsToGroup_totp_nonLogin() {
        let cipher = CipherListView.fixture(type: .card(.fixture()))
        XCTAssertFalse(cipher.belongsToGroup(.totp))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher has no folder and the group is `.noFolder`.
    func test_belongsToGroup_noFolder() {
        let cipher = CipherListView.fixture(folderId: nil)
        XCTAssertTrue(cipher.belongsToGroup(.noFolder))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher has a folder and the group is `.noFolder`.
    func test_belongsToGroup_noFolder_hasFolder() {
        let cipher = CipherListView.fixture(folderId: "folder-123")
        XCTAssertFalse(cipher.belongsToGroup(.noFolder))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher's folder ID matches the group's folder ID.
    func test_belongsToGroup_folder_matching() {
        let cipher = CipherListView.fixture(folderId: "folder-123")
        XCTAssertTrue(cipher.belongsToGroup(.folder(id: "folder-123", name: "My Folder")))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher's folder ID doesn't match the group's folder ID.
    func test_belongsToGroup_folder_notMatching() {
        let cipher = CipherListView.fixture(folderId: "folder-123")
        XCTAssertFalse(cipher.belongsToGroup(.folder(id: "folder-456", name: "Other Folder")))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher has no folder and the group is a specific folder.
    func test_belongsToGroup_folder_noFolderId() {
        let cipher = CipherListView.fixture(folderId: nil)
        XCTAssertFalse(cipher.belongsToGroup(.folder(id: "folder-123", name: "My Folder")))
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher's collection ID matches the group's collection ID.
    func test_belongsToGroup_collection_matching() {
        let cipher = CipherListView.fixture(collectionIds: ["collection-1", "collection-2"])
        XCTAssertTrue(
            cipher.belongsToGroup(
                .collection(
                    id: "collection-1",
                    name: "My Collection",
                    organizationId: "org-1",
                ),
            ),
        )
        XCTAssertTrue(
            cipher.belongsToGroup(
                .collection(
                    id: "collection-2",
                    name: "Other Collection",
                    organizationId: "org-1",
                ),
            ),
        )
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher's collection IDs don't include the group's collection ID.
    func test_belongsToGroup_collection_notMatching() {
        let cipher = CipherListView.fixture(collectionIds: ["collection-1", "collection-2"])
        XCTAssertFalse(
            cipher.belongsToGroup(
                .collection(
                    id: "collection-3",
                    name: "Missing Collection",
                    organizationId: "org-1",
                ),
            ),
        )
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher has no collections and the group is a collection.
    func test_belongsToGroup_collection_noCollections() {
        let cipher = CipherListView.fixture(collectionIds: [])
        XCTAssertFalse(
            cipher.belongsToGroup(
                .collection(
                    id: "collection-1",
                    name: "My Collection",
                    organizationId: "org-1",
                ),
            ),
        )
    }

    /// `belongsToGroup(_:)` returns `true` when the cipher is in trash and the group is `.trash`.
    func test_belongsToGroup_trash() {
        let cipher = CipherListView.fixture(deletedDate: Date())
        XCTAssertTrue(cipher.belongsToGroup(.trash))
    }

    /// `belongsToGroup(_:)` returns `false` when the cipher is not in trash and the group is `.trash`.
    func test_belongsToGroup_trash_notDeleted() {
        let cipher = CipherListView.fixture(deletedDate: nil)
        XCTAssertFalse(cipher.belongsToGroup(.trash))
    }

    /// `canBeUsedInBasicLoginAutofill` returns `false` when the cipher is not a login type.
    func test_canBeUsedInBasicLoginAutofill_nonLoginType() {
        XCTAssertFalse(CipherListView.fixture(type: .card(.fixture())).canBeUsedInBasicLoginAutofill)
        XCTAssertFalse(CipherListView.fixture(type: .identity).canBeUsedInBasicLoginAutofill)
        XCTAssertFalse(CipherListView.fixture(type: .secureNote).canBeUsedInBasicLoginAutofill)
        XCTAssertFalse(CipherListView.fixture(type: .sshKey).canBeUsedInBasicLoginAutofill)
    }

    /// `canBeUsedInBasicLoginAutofill` returns `false` when the login has no copyable login fields.
    func test_canBeUsedInBasicLoginAutofill_noLoginFields() {
        XCTAssertFalse(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `false` when the login has only non-login copyable fields.
    func test_canBeUsedInBasicLoginAutofill_onlyNonLoginFields() {
        XCTAssertFalse(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.cardNumber, .cardSecurityCode],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `true` when the login has a username field.
    func test_canBeUsedInBasicLoginAutofill_hasUsername() {
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginUsername],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `true` when the login has a password field.
    func test_canBeUsedInBasicLoginAutofill_hasPassword() {
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginPassword],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `true` when the login has a TOTP field.
    func test_canBeUsedInBasicLoginAutofill_hasTotp() {
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginTotp],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `true` when the login has multiple login fields.
    func test_canBeUsedInBasicLoginAutofill_hasMultipleLoginFields() {
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginUsername, .loginPassword, .loginTotp],
            ).canBeUsedInBasicLoginAutofill,
        )
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginUsername, .loginPassword],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `canBeUsedInBasicLoginAutofill` returns `true` when the login has login fields mixed with other fields.
    func test_canBeUsedInBasicLoginAutofill_hasLoginFieldsWithOtherFields() {
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.loginUsername, .cardNumber],
            ).canBeUsedInBasicLoginAutofill,
        )
        XCTAssertTrue(
            CipherListView.fixture(
                type: .login(.fixture()),
                copyableFields: [.cardSecurityCode, .loginPassword, .identityUsername],
            ).canBeUsedInBasicLoginAutofill,
        )
    }

    /// `matchesSearchQuery(_:)` returns `.exact` when query matches cipher name.
    func test_matchesSearchQuery_exactMatchOnName() {
        let cipher = CipherListView.fixture(name: "Example Site")
        XCTAssertEqual(cipher.matchesSearchQuery("example"), .exact)
        XCTAssertEqual(cipher.matchesSearchQuery("site"), .exact)
        XCTAssertEqual(cipher.matchesSearchQuery("example site"), .exact)
    }

    /// `matchesSearchQuery(_:)` returns `.exact` for case-insensitive name matching.
    func test_matchesSearchQuery_exactMatchCaseInsensitive() {
        let cipher = CipherListView.fixture(name: "Example Site")
        XCTAssertEqual(cipher.matchesSearchQuery("example"), .exact)

        let cipher2 = CipherListView.fixture(name: "EXAMPLE SITE")
        XCTAssertEqual(cipher2.matchesSearchQuery("example"), .exact)
    }

    /// `matchesSearchQuery(_:)` returns `.exact` for diacritic-insensitive name matching.
    func test_matchesSearchQuery_exactMatchDiacriticInsensitive() {
        let cipher = CipherListView.fixture(name: "Café")
        XCTAssertEqual(cipher.matchesSearchQuery("cafe"), .exact)
    }

    /// `matchesSearchQuery(_:)` returns `.fuzzy` when query matches cipher ID prefix with 8+ characters.
    func test_matchesSearchQuery_fuzzyMatchOnIdPrefix() {
        let cipher = CipherListView.fixture(id: "12345678-90ab-cdef-1234-567890abcdef")
        XCTAssertEqual(cipher.matchesSearchQuery("12345678"), .fuzzy)
        XCTAssertEqual(cipher.matchesSearchQuery("12345678-90ab"), .fuzzy)
    }

    /// `matchesSearchQuery(_:)` returns `.none` when query matches ID but is less than 8 characters.
    func test_matchesSearchQuery_noMatchOnShortIdPrefix() {
        let cipher = CipherListView.fixture(id: "12345678-90ab-cdef-1234-567890abcdef")
        XCTAssertEqual(cipher.matchesSearchQuery("1234567"), .none)
        XCTAssertEqual(cipher.matchesSearchQuery("123"), .none)
    }

    /// `matchesSearchQuery(_:)` returns `.fuzzy` when query matches cipher subtitle.
    func test_matchesSearchQuery_fuzzyMatchOnSubtitle() {
        let cipher = CipherListView.fixture(name: "MySite", subtitle: "user@example.com")
        XCTAssertEqual(cipher.matchesSearchQuery("user"), .fuzzy)
        XCTAssertEqual(cipher.matchesSearchQuery("example"), .fuzzy)
    }

    /// `matchesSearchQuery(_:)` returns `.fuzzy` for case-insensitive subtitle matching.
    func test_matchesSearchQuery_fuzzyMatchSubtitleCaseInsensitive() {
        let cipher = CipherListView.fixture(name: "MySite", subtitle: "Admin User")
        XCTAssertEqual(cipher.matchesSearchQuery("admin"), .fuzzy)
        XCTAssertEqual(cipher.matchesSearchQuery("user"), .fuzzy)
    }

    /// `matchesSearchQuery(_:)` returns `.fuzzy` when query matches login URI.
    func test_matchesSearchQuery_fuzzyMatchOnUri() {
        let login = LoginListView.fixture(
            uris: [LoginUriView(uri: "https://example.com", match: nil, uriChecksum: nil)],
        )
        let cipher = CipherListView.fixture(login: login, name: "MySite")
        XCTAssertEqual(cipher.matchesSearchQuery("example.com"), .fuzzy)
        XCTAssertEqual(cipher.matchesSearchQuery("https://"), .fuzzy)
    }

    /// `matchesSearchQuery(_:)` returns `.fuzzy` when query matches any URI in multiple URIs.
    func test_matchesSearchQuery_fuzzyMatchOnMultipleUris() {
        let login = LoginListView.fixture(
            uris: [
                LoginUriView(uri: "https://example.com", match: nil, uriChecksum: nil),
                LoginUriView(uri: "https://test.com", match: nil, uriChecksum: nil),
                LoginUriView(uri: "https://demo.org", match: nil, uriChecksum: nil),
            ],
        )
        let cipher = CipherListView.fixture(login: login, name: "MySite")
        XCTAssertEqual(cipher.matchesSearchQuery("test.com"), .fuzzy)
        XCTAssertEqual(cipher.matchesSearchQuery("demo"), .fuzzy)
    }

    /// `matchesSearchQuery(_:)` returns `.none` when query matches nothing.
    func test_matchesSearchQuery_noMatch() {
        let cipher = CipherListView.fixture(name: "Example", subtitle: "test@example.com")
        XCTAssertEqual(cipher.matchesSearchQuery("nonexistent"), .none)
        XCTAssertEqual(cipher.matchesSearchQuery("xyz"), .none)
    }

    /// `matchesSearchQuery(_:)` prioritizes exact match over fuzzy match.
    func test_matchesSearchQuery_exactMatchPriority() {
        let login = LoginListView.fixture(
            uris: [LoginUriView(uri: "https://example.com", match: nil, uriChecksum: nil)],
        )
        let cipher = CipherListView.fixture(login: login, name: "Example Site", subtitle: "example")
        XCTAssertEqual(cipher.matchesSearchQuery("example"), .exact)
    }

    /// `matchesSearchQuery(_:)` handles empty query.
    func test_matchesSearchQuery_emptyQuery() {
        let cipher = CipherListView.fixture(name: "Example")
        XCTAssertEqual(cipher.matchesSearchQuery(""), .none)
    }

    /// `matchesSearchQuery(_:)` handles cipher with nil ID.
    func test_matchesSearchQuery_nilId() {
        let cipher = CipherListView.fixture(id: nil, name: "Example")
        XCTAssertEqual(cipher.matchesSearchQuery("12345678"), .none)
        XCTAssertEqual(cipher.matchesSearchQuery("example"), .exact)
    }

    /// `matchesSearchQuery(_:)` handles cipher with nil URIs.
    func test_matchesSearchQuery_nilUris() {
        let login = LoginListView.fixture(uris: nil)
        let cipher = CipherListView.fixture(login: login, name: "MySite")
        XCTAssertEqual(cipher.matchesSearchQuery("example.com"), .none)
        XCTAssertEqual(cipher.matchesSearchQuery("mysite"), .exact)
    }

    /// `isArchived` returns `true` when there's an archived date, `false` otherwise.
    func test_isArchived() {
        XCTAssertTrue(CipherListView.fixture(archivedDate: .now).isArchived)
        XCTAssertFalse(CipherListView.fixture(archivedDate: nil).isArchived)
    }

    /// `isHidden` return `true` when the cipher is hidden, i.e. archived or deleted; `false` otherwise.
    func test_isHidden() {
        XCTAssertTrue(CipherListView.fixture(archivedDate: .now).isHidden)
        XCTAssertTrue(CipherListView.fixture(deletedDate: .now).isHidden)
        XCTAssertTrue(CipherListView.fixture(deletedDate: .now, archivedDate: .now).isHidden)
        XCTAssertFalse(CipherListView.fixture(deletedDate: nil, archivedDate: nil).isHidden)
    }

    /// `isHiddenWithArchiveFF` returns `true` when cipher is deleted, regardless of feature flag state.
    func test_isHiddenWithArchiveFF_deleted() {
        let deletedCipher = CipherListView.fixture(deletedDate: .now, archivedDate: nil)
        XCTAssertTrue(deletedCipher.isHiddenWithArchiveFF(flag: true))
        XCTAssertTrue(deletedCipher.isHiddenWithArchiveFF(flag: false))
    }

    /// `isHiddenWithArchiveFF` returns `true` when cipher is both archived and deleted,
    /// regardless of feature flag state.
    func test_isHiddenWithArchiveFF_archivedAndDeleted() {
        let archivedAndDeletedCipher = CipherListView.fixture(deletedDate: .now, archivedDate: .now)
        XCTAssertTrue(archivedAndDeletedCipher.isHiddenWithArchiveFF(flag: true))
        XCTAssertTrue(archivedAndDeletedCipher.isHiddenWithArchiveFF(flag: false))
    }

    /// `isHiddenWithArchiveFF` returns `true` when cipher is archived and feature flag is enabled.
    func test_isHiddenWithArchiveFF_archivedWithFlagEnabled() {
        let archivedCipher = CipherListView.fixture(deletedDate: nil, archivedDate: .now)
        XCTAssertTrue(archivedCipher.isHiddenWithArchiveFF(flag: true))
    }

    /// `isHiddenWithArchiveFF` returns `false` when cipher is archived but feature flag is disabled.
    func test_isHiddenWithArchiveFF_archivedWithFlagDisabled() {
        let archivedCipher = CipherListView.fixture(deletedDate: nil, archivedDate: .now)
        XCTAssertFalse(archivedCipher.isHiddenWithArchiveFF(flag: false))
    }

    /// `isHiddenWithArchiveFF` returns `false` when cipher is neither archived nor deleted,
    /// regardless of feature flag state.
    func test_isHiddenWithArchiveFF_notHidden() {
        let normalCipher = CipherListView.fixture(deletedDate: nil, archivedDate: nil)
        XCTAssertFalse(normalCipher.isHiddenWithArchiveFF(flag: true))
        XCTAssertFalse(normalCipher.isHiddenWithArchiveFF(flag: false))
    }

    /// `passesRestrictItemTypesPolicy(_:)` passes the policy when there are no organization IDs.
    func test_passesRestrictItemTypesPolicy_noOrgIds() {
        XCTAssertTrue(CipherListView.fixture().passesRestrictItemTypesPolicy([]))
    }

    /// `passesRestrictItemTypesPolicy(_:)` passes the policy when the cipher type is not `.card`.
    func test_passesRestrictItemTypesPolicy_noCardType() {
        XCTAssertTrue(CipherListView.fixture(type: .login(.fixture())).passesRestrictItemTypesPolicy(["1"]))
        XCTAssertTrue(CipherListView.fixture(type: .identity).passesRestrictItemTypesPolicy(["1"]))
        XCTAssertTrue(CipherListView.fixture(type: .secureNote).passesRestrictItemTypesPolicy(["1"]))
        XCTAssertTrue(CipherListView.fixture(type: .sshKey).passesRestrictItemTypesPolicy(["1"]))
    }

    /// `passesRestrictItemTypesPolicy(_:)` doesn't pass the policy when there are organization IDs,
    /// cipher type is `.card` but cipher doesn't belong to an organization or such organization has empty ID.
    func test_passesRestrictItemTypesPolicy_noCipherOrganizationId() {
        XCTAssertFalse(
            CipherListView.fixture(organizationId: nil, type: .card(.fixture())).passesRestrictItemTypesPolicy(["1"]),
        )
        XCTAssertFalse(
            CipherListView.fixture(organizationId: "", type: .card(.fixture())).passesRestrictItemTypesPolicy(["1"]),
        )
    }

    /// `passesRestrictItemTypesPolicy(_:)` doesn't pass the policy when there are organization IDs,
    /// cipher type is `.card`, cipher belongs to an organization but it's part of the restricted IDs.
    func test_passesRestrictItemTypesPolicy_restrictedOrganizationId() {
        XCTAssertFalse(
            CipherListView.fixture(organizationId: "2", type: .card(.fixture()))
                .passesRestrictItemTypesPolicy(["1", "2", "3"]),
        )
    }

    /// `passesRestrictItemTypesPolicy(_:)` pass the policy when there are organization IDs,
    /// cipher type is `.card`, cipher belongs to an organization that isn't part of the restricted IDs.
    func test_passesRestrictItemTypesPolicy_passOnNonRestrictedOrganizationId() {
        XCTAssertTrue(
            CipherListView.fixture(organizationId: "5", type: .card(.fixture()))
                .passesRestrictItemTypesPolicy(["1", "2", "3"]),
        )
    }
} // swiftlint:disable:this file_length
