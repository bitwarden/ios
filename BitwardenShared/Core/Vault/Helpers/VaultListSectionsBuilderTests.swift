import BitwardenKitMocks
import BitwardenResources
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - VaultListSectionsBuilderTests

class VaultListSectionsBuilderTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var clientService: MockClientService!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DefaultVaultListSectionsBuilder!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        configService = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `addAutofillCombinedMultipleSection()` adds separate sections for passwords and Fido2 items with rpID.
    func test_addAutofillCombinedMultipleSection() {
        setUpSubject(withData: VaultListPreparedData(
            fido2Items: [
                .fixture(cipherListView: .fixture(id: "3", name: "Fido2-1"), fido2CredentialAutofillView: .fixture()),
                .fixture(cipherListView: .fixture(id: "6", name: "zFido2-2"), fido2CredentialAutofillView: .fixture()),
            ],
            groupItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Password-3")),
                .fixture(cipherListView: .fixture(id: "2", name: "Password-1")),
                .fixture(cipherListView: .fixture(id: "4", name: "Password-2")),
            ],
        ))

        let vaultListData = subject.addAutofillCombinedMultipleSection(rpID: "example.com").build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Passkeys for example.com]: Passkeys for example.com
              - Cipher: Fido2-1
              - Cipher: zFido2-2
            Section[Passwords for example.com]: Passwords for example.com
              - Cipher: Password-1
              - Cipher: Password-2
              - Cipher: Password-3
            """
        }
    }

    /// `addAutofillCombinedMultipleSection()` adds only passwords section when no rpID provided.
    func test_addAutofillCombinedMultipleSection_noRpID() {
        setUpSubject(withData: VaultListPreparedData(
            fido2Items: [
                .fixture(cipherListView: .fixture(id: "3", name: "Fido2-1"), fido2CredentialAutofillView: .fixture()),
            ],
            groupItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Password-1")),
                .fixture(cipherListView: .fixture(id: "2", name: "Password-2")),
            ],
        ))

        let vaultListData = subject.addAutofillCombinedMultipleSection(rpID: nil).build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Passwords]: Passwords
              - Cipher: Password-1
              - Cipher: Password-2
            """
        }
    }

    /// `addAutofillCombinedMultipleSection()` adds only passwords section when Fido2 items exist but no rpID.
    func test_addAutofillCombinedMultipleSection_onlyPasswords() {
        setUpSubject(withData: VaultListPreparedData(
            fido2Items: [],
            groupItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Password-3")),
                .fixture(cipherListView: .fixture(id: "2", name: "Password-1")),
            ],
        ))

        let vaultListData = subject.addAutofillCombinedMultipleSection(rpID: "example.com").build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Passwords for example.com]: Passwords for example.com
              - Cipher: Password-1
              - Cipher: Password-3
            """
        }
    }

    /// `addAutofillCombinedMultipleSection()` adds only Fido2 section when no passwords but rpID provided.
    func test_addAutofillCombinedMultipleSection_onlyFido2() {
        setUpSubject(withData: VaultListPreparedData(
            fido2Items: [
                .fixture(cipherListView: .fixture(id: "1", name: "Fido2-2"), fido2CredentialAutofillView: .fixture()),
                .fixture(cipherListView: .fixture(id: "2", name: "Fido2-1"), fido2CredentialAutofillView: .fixture()),
            ],
            groupItems: [],
        ))

        let vaultListData = subject.addAutofillCombinedMultipleSection(rpID: "example.com").build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Passkeys for example.com]: Passkeys for example.com
              - Cipher: Fido2-1
              - Cipher: Fido2-2
            """
        }
    }

    /// `addAutofillCombinedMultipleSection()` doesn't add any sections when no items available.
    func test_addAutofillCombinedMultipleSection_empty() {
        setUpSubject(withData: VaultListPreparedData(
            fido2Items: [],
            groupItems: [],
        ))

        let vaultListData = subject.addAutofillCombinedMultipleSection(rpID: "example.com").build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            """
        }
    }

    /// `addAutofillCombinedSingleSection()` adds a vault section combining passwords and Fido2 items.
    func test_addAutofillCombinedSingleSection() {
        setUpSubject(withData: VaultListPreparedData(
            fido2Items: [
                .fixture(cipherListView: .fixture(id: "3", name: "Fido2-1"), fido2CredentialAutofillView: .fixture()),
                .fixture(cipherListView: .fixture(id: "6", name: "zFido2-2"), fido2CredentialAutofillView: .fixture()),
            ],
            groupItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Password-3")),
                .fixture(cipherListView: .fixture(id: "2", name: "Password-1")),
                .fixture(cipherListView: .fixture(id: "4", name: "Password-2")),
            ],
        ))

        let vaultListData = subject.addAutofillCombinedSingleSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Choose a login to save this passkey to]: Choose a login to save this passkey to
              - Cipher: Fido2-1
              - Cipher: Password-1
              - Cipher: Password-2
              - Cipher: Password-3
              - Cipher: zFido2-2
            """
        }
    }

    /// `addAutofillCombinedSingleSection()` doesn't add a vault section when no passwords no Fido2 items available.
    func test_addAutofillCombinedSingleSection_empty() {
        setUpSubject(withData: VaultListPreparedData(
            fido2Items: [],
            groupItems: [],
        ))

        let vaultListData = subject.addAutofillCombinedSingleSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            """
        }
    }

    /// `addAutofillPasswordsSection()` adds a vault section combining exact and fuzzy match items.
    func test_addAutofillPasswordsSection() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Exact42")),
                .fixture(cipherListView: .fixture(id: "2", name: "Exact1")),
                .fixture(cipherListView: .fixture(id: "4", name: "Exact2")),
            ],
            fuzzyMatchItems: [
                .fixture(cipherListView: .fixture(id: "3", name: "Fuzzy11")),
                .fixture(cipherListView: .fixture(id: "6", name: "Fuzzy10")),
            ],
        ))

        let vaultListData = subject.addAutofillPasswordsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[AutofillPasswords]: 
              - Cipher: Exact1
              - Cipher: Exact2
              - Cipher: Exact42
              - Cipher: Fuzzy10
              - Cipher: Fuzzy11
            """
        }
    }

    /// `addAutofillPasswordsSection()` adds a vault section with exact match items when no fuzzy items are present.
    func test_addAutofillPasswordsSection_onlyExact() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Exact42")),
                .fixture(cipherListView: .fixture(id: "2", name: "Exact1")),
                .fixture(cipherListView: .fixture(id: "4", name: "Exact2")),
            ],
            fuzzyMatchItems: [],
        ))

        let vaultListData = subject.addAutofillPasswordsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[AutofillPasswords]: 
              - Cipher: Exact1
              - Cipher: Exact2
              - Cipher: Exact42
            """
        }
    }

    /// `addAutofillPasswordsSection()` adds a vault section with fuzzy match items when no exact items are present.
    func test_addAutofillPasswordsSection_onlyFuzzy() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [],
            fuzzyMatchItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Fuzzy42")),
                .fixture(cipherListView: .fixture(id: "2", name: "Fuzzy1")),
                .fixture(cipherListView: .fixture(id: "4", name: "Fuzzy2")),
            ],
        ))

        let vaultListData = subject.addAutofillPasswordsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[AutofillPasswords]: 
              - Cipher: Fuzzy1
              - Cipher: Fuzzy2
              - Cipher: Fuzzy42
            """
        }
    }

    /// `addAutofillPasswordsSection()` doesn't add vault section when no exact nor fuzzy match items.
    func test_addAutofillPasswordsSection_empty() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [],
            fuzzyMatchItems: [],
        ))

        let vaultListData = subject.addAutofillPasswordsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            """
        }
    }

    /// `addCipherDecryptionFailureIds()` adds the list of cipher decryption failure IDs to the vault list data.
    func test_addCipherDecryptionFailuresIds() {
        setUpSubject(withData: VaultListPreparedData(cipherDecryptionFailureIds: ["1", "2", "3"]))
        let vaultListData = subject.addCipherDecryptionFailureIds().build()
        XCTAssertEqual(vaultListData.cipherDecryptionFailureIds, ["1", "2", "3"])
    }

    /// `addFavoritesSection()` adds the favorites section with the favorite items ordered by name.
    func test_addFavoritesSection() {
        setUpSubject(
            withData: VaultListPreparedData(
                favorites: [
                    .fixture(cipherListView: .fixture(id: "1", name: "MyFavoriteItem2")),
                    .fixture(cipherListView: .fixture(id: "2", name: "MyFavoriteItem45")),
                    .fixture(cipherListView: .fixture(id: "3", name: "MyFavoriteItem0")),
                ],
            ),
        )

        let vaultListData = subject.addFavoritesSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Favorites]: Favorites
              - Cipher: MyFavoriteItem0
              - Cipher: MyFavoriteItem2
              - Cipher: MyFavoriteItem45
            """
        }
    }

    /// `addFavoritesSection()` doesn't add the favorites section when no favorites.
    func test_addFavoritesSection_empty() {
        setUpSubject(
            withData: VaultListPreparedData(
                favorites: [],
            ),
        )

        let vaultListData = subject.addFavoritesSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            """
        }
    }

    /// `addGroupSection()` adds the group section with the group items ordered by name.
    func test_addGroupSection() {
        setUpSubject(
            withData: VaultListPreparedData(
                groupItems: [
                    .fixture(cipherListView: .fixture(id: "1", name: "MyItem2")),
                    .fixture(cipherListView: .fixture(id: "2", name: "MyItem45")),
                    .fixture(cipherListView: .fixture(id: "3", name: "MyItem0")),
                ],
            ),
        )

        let vaultListData = subject.addGroupSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Items]: Items
              - Cipher: MyItem0
              - Cipher: MyItem2
              - Cipher: MyItem45
            """
        }
    }

    /// `addGroupSection()` adds nothing if there are no group items in the prepared data.
    func test_addGroupSection_empty() {
        setUpSubject(
            withData: VaultListPreparedData(
                groupItems: [],
            ),
        )

        let vaultListData = subject.addGroupSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            """
        }
    }

    /// `addHiddenItemsSection()` adds the hidden items section to the list of sections with the count
    /// of deleted ciphers when the archive feature flag is off.
    @MainActor
    func test_addHiddenItemsSection_archiveFeatureFlagDisabled() async {
        configService.featureFlagsBool[.archiveVaultItems] = false
        setUpSubject(withData: VaultListPreparedData(ciphersDeletedCount: 10))

        let vaultListData = await subject.addHiddenItemsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[HiddenItems]: Hidden items
              - Group[Trash]: Trash (10)
            """
        }
    }

    /// `addHiddenItemsSection()` adds the hidden items section with archive when the feature flag is on
    /// and the user has premium.
    @MainActor
    func test_addHiddenItemsSection_archiveFeatureFlagEnabled_hasPremium() async {
        configService.featureFlagsBool[.archiveVaultItems] = true
        stateService.doesActiveAccountHavePremiumResult = true
        setUpSubject(withData: VaultListPreparedData(
            ciphersArchivedCount: 5,
            ciphersDeletedCount: 10,
        ))

        let vaultListData = await subject.addHiddenItemsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[HiddenItems]: Hidden items
              - Group[Archive]: Archive (5)
              - Group[Trash]: Trash (10)
            """
        }

        // Verify hasPremium is correctly set on the Archive item
        let archiveItem = vaultListData.sections.first?.items.first { $0.id == "Archive" }
        XCTAssertEqual(archiveItem?.hasPremium, true)
    }

    /// `addHiddenItemsSection()` adds archive when the feature flag is on even if the user
    /// does not have premium and there are no archived items, showing premium required UI.
    @MainActor
    func test_addHiddenItemsSection_archiveFeatureFlagEnabled_noPremium_noArchivedItems() async {
        configService.featureFlagsBool[.archiveVaultItems] = true
        stateService.doesActiveAccountHavePremiumResult = false
        setUpSubject(withData: VaultListPreparedData(
            ciphersArchivedCount: 0,
            ciphersDeletedCount: 10,
        ))

        let vaultListData = await subject.addHiddenItemsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[HiddenItems]: Hidden items
              - Group[Archive]: Archive (0)
              - Group[Trash]: Trash (10)
            """
        }

        // Verify hasPremium is correctly set on the Archive item
        let archiveItem = vaultListData.sections.first?.items.first { $0.id == "Archive" }
        XCTAssertEqual(archiveItem?.hasPremium, false)

        // Verify that premium subscription is required (should show locked icon and subtitle)
        XCTAssertEqual(archiveItem?.subtitle, Localizations.premiumSubscriptionRequired)
        XCTAssertEqual(archiveItem?.accessoryIcon?.name, SharedAsset.Icons.locked24.name)
    }

    /// `addHiddenItemsSection()` adds archive when the feature flag is on and the user
    /// does not have premium but there are archived items.
    @MainActor
    func test_addHiddenItemsSection_archiveFeatureFlagEnabled_noPremium_hasArchivedItems() async {
        configService.featureFlagsBool[.archiveVaultItems] = true
        stateService.doesActiveAccountHavePremiumResult = false
        setUpSubject(withData: VaultListPreparedData(
            ciphersArchivedCount: 3,
            ciphersDeletedCount: 10,
        ))

        let vaultListData = await subject.addHiddenItemsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[HiddenItems]: Hidden items
              - Group[Archive]: Archive (3)
              - Group[Trash]: Trash (10)
            """
        }

        // Verify hasPremium is correctly set on the Archive item
        let archiveItem = vaultListData.sections.first?.items.first { $0.id == "Archive" }
        XCTAssertEqual(archiveItem?.hasPremium, false)

        // Verify that premium subscription is NOT required since there are archived items
        XCTAssertNil(archiveItem?.subtitle)
        XCTAssertNil(archiveItem?.accessoryIcon)
    }

    /// `addTOTPSection()` adds the TOTP section with an item when there are TOTP items.
    func test_addTOTPSection() {
        setUpSubject(
            withData: VaultListPreparedData(
                totpItemsCount: 20,
            ),
        )

        let vaultListData = subject.addTOTPSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[TOTP]: TOTP
              - Group[Types.VerificationCodes]: Verification codes (20)
            """
        }
    }

    /// `addTOTPSection()` doesn't add the TOTP section when there are no TOTP items.
    func test_addTOTPSection_empty() {
        setUpSubject(
            withData: VaultListPreparedData(
                totpItemsCount: 0,
            ),
        )

        let vaultListData = subject.addTOTPSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            """
        }
    }

    /// `addTypesSection()` adds the Types section with each item type count, or 0 if not found.
    func test_addTypesSection() {
        setUpSubject(
            withData: VaultListPreparedData(
                countPerCipherType: [
                    .card: 10,
                    .identity: 1,
                    .login: 15,
                    .secureNote: 2,
                ],
            ),
        )

        let vaultListData = subject.addTypesSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Types]: Types
              - Group[Types.Logins]: Login (15)
              - Group[Types.Cards]: Card (10)
              - Group[Types.Identities]: Identity (1)
              - Group[Types.SecureNotes]: Secure note (2)
              - Group[Types.SSHKeys]: SSH key (0)
            """
        }
    }

    /// `addTypesSection()` adds the Types section with each item type count, or 0 if not found
    /// with restrictedOrganizationIds and cards.
    func test_addTypesSection_restrictedOrganizationIds_cards() {
        setUpSubject(
            withData: VaultListPreparedData(
                countPerCipherType: [
                    .card: 10,
                    .identity: 1,
                    .login: 15,
                    .secureNote: 2,
                ],
                restrictedOrganizationIds: ["org1", "org2"],
            ),
        )

        let vaultListData = subject.addTypesSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Types]: Types
              - Group[Types.Logins]: Login (15)
              - Group[Types.Cards]: Card (10)
              - Group[Types.Identities]: Identity (1)
              - Group[Types.SecureNotes]: Secure note (2)
              - Group[Types.SSHKeys]: SSH key (0)
            """
        }
    }

    /// `addTypesSection()` adds the Types section with each item type count, or 0 if not found
    /// with restrictedOrganizationIds but no cards.
    func test_addTypesSection_restrictedOrganizationIds_nocards() {
        setUpSubject(
            withData: VaultListPreparedData(
                countPerCipherType: [
                    .card: 0,
                    .identity: 1,
                    .login: 15,
                    .secureNote: 2,
                ],
                restrictedOrganizationIds: ["org1", "org2"],
            ),
        )

        let vaultListData = subject.addTypesSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Types]: Types
              - Group[Types.Logins]: Login (15)
              - Group[Types.Identities]: Identity (1)
              - Group[Types.SecureNotes]: Secure note (2)
              - Group[Types.SSHKeys]: SSH key (0)
            """
        }
    }

    // MARK: addSearchResultsSection Tests

    /// `addSearchResultsSection(options:)` adds a search results section with exact and fuzzy match items combined.
    func test_addSearchResultsSection_exactAndFuzzyMatches() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Exact-2")),
                .fixture(cipherListView: .fixture(id: "2", name: "Exact-1")),
                .fixture(cipherListView: .fixture(id: "4", name: "Exact-3")),
            ],
            fuzzyMatchItems: [
                .fixture(cipherListView: .fixture(id: "3", name: "Fuzzy-2")),
                .fixture(cipherListView: .fixture(id: "6", name: "Fuzzy-1")),
            ],
        ))

        let vaultListData = subject.addSearchResultsSection(options: []).build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[SearchResults]: 
              - Cipher: Exact-1
              - Cipher: Exact-2
              - Cipher: Exact-3
              - Cipher: Fuzzy-1
              - Cipher: Fuzzy-2
            """
        }
    }

    /// `addSearchResultsSection(options:)` adds a search results section with only exact match items
    /// when no fuzzy items.
    func test_addSearchResultsSection_onlyExactMatches() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Item-C")),
                .fixture(cipherListView: .fixture(id: "2", name: "Item-A")),
                .fixture(cipherListView: .fixture(id: "3", name: "Item-B")),
            ],
            fuzzyMatchItems: [],
        ))

        let vaultListData = subject.addSearchResultsSection(options: []).build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[SearchResults]: 
              - Cipher: Item-A
              - Cipher: Item-B
              - Cipher: Item-C
            """
        }
    }

    /// `addSearchResultsSection(options:)` adds a search results section with only fuzzy match items
    /// when no exact items.
    func test_addSearchResultsSection_onlyFuzzyMatches() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [],
            fuzzyMatchItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Fuzzy-3")),
                .fixture(cipherListView: .fixture(id: "2", name: "Fuzzy-1")),
                .fixture(cipherListView: .fixture(id: "3", name: "Fuzzy-2")),
            ],
        ))

        let vaultListData = subject.addSearchResultsSection(options: []).build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[SearchResults]: 
              - Cipher: Fuzzy-1
              - Cipher: Fuzzy-2
              - Cipher: Fuzzy-3
            """
        }
    }

    /// `addSearchResultsSection(options:)` doesn't add a section when there are no exact or fuzzy match items.
    func test_addSearchResultsSection_empty() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [],
            fuzzyMatchItems: [],
        ))

        let vaultListData = subject.addSearchResultsSection(options: []).build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            """
        }
    }

    /// `addSearchResultsSection(options:)` sorts exact and fuzzy match items together alphabetically by name.
    func test_addSearchResultsSection_sortingOrder() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Zebra")),
                .fixture(cipherListView: .fixture(id: "2", name: "Apple")),
                .fixture(cipherListView: .fixture(id: "3", name: "Banana")),
            ],
            fuzzyMatchItems: [
                .fixture(cipherListView: .fixture(id: "4", name: "Xylophone")),
                .fixture(cipherListView: .fixture(id: "5", name: "Cherry")),
                .fixture(cipherListView: .fixture(id: "6", name: "Mango")),
            ],
        ))

        let vaultListData = subject.addSearchResultsSection(options: []).build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[SearchResults]: 
              - Cipher: Apple
              - Cipher: Banana
              - Cipher: Cherry
              - Cipher: Mango
              - Cipher: Xylophone
              - Cipher: Zebra
            """
        }
    }

    /// `addSearchResultsSection(options:)` correctly handles single exact match item.
    func test_addSearchResultsSection_singleExactMatch() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "SingleItem")),
            ],
            fuzzyMatchItems: [],
        ))

        let vaultListData = subject.addSearchResultsSection(options: []).build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[SearchResults]: 
              - Cipher: SingleItem
            """
        }
    }

    /// `addSearchResultsSection(options:)` correctly handles single fuzzy match item.
    func test_addSearchResultsSection_singleFuzzyMatch() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [],
            fuzzyMatchItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "FuzzyItem")),
            ],
        ))

        let vaultListData = subject.addSearchResultsSection(options: []).build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[SearchResults]: 
              - Cipher: FuzzyItem
            """
        }
    }

    /// `addSearchResultsSection(options:)` adds a search results section with exact and fuzzy match items combined
    /// in picker mode.
    func test_addSearchResultsSection_exactAndFuzzyMatchesPickerMode() {
        setUpSubject(withData: VaultListPreparedData(
            exactMatchItems: [
                .fixture(cipherListView: .fixture(id: "1", name: "Exact-2")),
                .fixture(cipherListView: .fixture(id: "2", name: "Exact-1")),
                .fixture(cipherListView: .fixture(id: "4", name: "Exact-3")),
            ],
            fuzzyMatchItems: [
                .fixture(cipherListView: .fixture(id: "3", name: "Fuzzy-2")),
                .fixture(cipherListView: .fixture(id: "6", name: "Fuzzy-1")),
            ],
        ))

        let vaultListData = subject.addSearchResultsSection(options: [.isInPickerMode]).build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[\(Localizations.matchingItems)]: \(Localizations.matchingItems)
              - Cipher: Exact-1
              - Cipher: Exact-2
              - Cipher: Exact-3
              - Cipher: Fuzzy-1
              - Cipher: Fuzzy-2
            """
        }
    }

    /// `build()` returns the built sections.
    /// Using this test also to verify that sections get appended and to verify fluent code usage of the builder.
    func test_build() async throws { // swiftlint:disable:this function_body_length
        setUpSubject(
            withData: VaultListPreparedData(
                ciphersDeletedCount: 10,
                collections: [.fixture(id: "1", name: "Collection 1")],
                collectionsCount: ["1": 5],
                countPerCipherType: [
                    .card: 10,
                    .identity: 1,
                    .login: 15,
                    .secureNote: 2,
                ],
                favorites: [.fixture(cipherListView: .fixture(name: "Favorite 1"))],
                folders: [.fixture(id: "1", name: "Folder 1")],
                foldersCount: ["1": 60],
                groupItems: [.fixture(cipherListView: .fixture(name: "Group cipher 1"))],
                noFolderItems: [.fixture(cipherListView: .fixture(name: "No folder 1"))],
                totpItemsCount: 20,
            ),
        )

        let vaultListData = try await subject
            .addHiddenItemsSection()
            .addCollectionsSection()
            .addFavoritesSection()
            .addFoldersSection()
            .addGroupSection()
            .addTOTPSection()
            .addTypesSection()
            .build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[HiddenItems]: Hidden items
              - Group[Trash]: Trash (10)
            Section[Collections]: Collections
              - Group[1]: Collection 1 (5)
            Section[Favorites]: Favorites
              - Cipher: Favorite 1
            Section[Folders]: Folders
              - Group[1]: Folder 1 (60)
              - Group[NoFolderFolderItem]: No Folder (1)
            Section[Items]: Items
              - Cipher: Group cipher 1
            Section[TOTP]: TOTP
              - Group[Types.VerificationCodes]: Verification codes (20)
            Section[Types]: Types
              - Group[Types.Logins]: Login (15)
              - Group[Types.Cards]: Card (10)
              - Group[Types.Identities]: Identity (1)
              - Group[Types.SecureNotes]: Secure note (2)
              - Group[Types.SSHKeys]: SSH key (0)
            """
        }
    }

    // MARK: Private

    /// Sets up the subject with the appropriate `VaultListPreparedData`.
    func setUpSubject(withData: VaultListPreparedData) {
        let collectionHelper = MockCollectionHelper()
        collectionHelper.orderClosure = { collections in collections }
        subject = DefaultVaultListSectionsBuilder(
            clientService: clientService,
            collectionHelper: collectionHelper,
            configService: configService,
            errorReporter: errorReporter,
            stateService: stateService,
            withData: withData,
        )
    }
} // swiftlint:disable:this file_length
