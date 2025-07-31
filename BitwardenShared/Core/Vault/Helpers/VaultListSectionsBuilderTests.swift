import BitwardenKitMocks
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - VaultListSectionsBuilderTests

class VaultListSectionsBuilderTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var subject: DefaultVaultListSectionsBuilder!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        errorReporter = MockErrorReporter()
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `addAutofillPasswordsSection()` adds a vault section combinining exact and fuzzy match items.
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
            ]
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
            fuzzyMatchItems: []
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
            ]
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
            fuzzyMatchItems: []
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
                ]
            )
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
                favorites: []
            )
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
                ]
            )
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
                groupItems: []
            )
        )

        let vaultListData = subject.addGroupSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            """
        }
    }

    /// `addTOTPSection()` adds the TOTP section with an item when there are TOTP items.
    func test_addTOTPSection() {
        setUpSubject(
            withData: VaultListPreparedData(
                totpItemsCount: 20
            )
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
                totpItemsCount: 0
            )
        )

        let vaultListData = subject.addTOTPSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            """
        }
    }

    /// `addTrashSection()` adds the trash section to the list of sections with the count of deleted ciphers.
    func test_addTrashSection() {
        setUpSubject(withData: VaultListPreparedData(ciphersDeletedCount: 10))

        let vaultListData = subject.addTrashSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Trash]: Trash
              - Group[Trash]: Trash (10)
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
                ]
            )
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
            )
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
            )
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
                totpItemsCount: 20
            )
        )

        let vaultListData = try await subject
            .addTrashSection()
            .addCollectionsSection()
            .addFavoritesSection()
            .addFoldersSection()
            .addGroupSection()
            .addTOTPSection()
            .addTypesSection()
            .build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Trash]: Trash
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
        subject = DefaultVaultListSectionsBuilder(
            clientService: clientService,
            errorReporter: errorReporter,
            withData: withData
        )
    }
} // swiftlint:disable:this file_length
