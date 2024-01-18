import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var cipherService: MockCipherService!
    var client: MockHTTPClient!
    var clientAuth: MockClientAuth!
    var clientCiphers: MockClientCiphers!
    var clientCrypto: MockClientCrypto!
    var clientVault: MockClientVaultService!
    var collectionService: MockCollectionService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var folderService: MockFolderService!
    var organizationService: MockOrganizationService!
    var stateService: MockStateService!
    var subject: DefaultVaultRepository!
    var syncService: MockSyncService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        client = MockHTTPClient()
        clientAuth = MockClientAuth()
        clientCiphers = MockClientCiphers()
        clientCrypto = MockClientCrypto()
        clientVault = MockClientVaultService()
        collectionService = MockCollectionService()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        folderService = MockFolderService()
        organizationService = MockOrganizationService()
        syncService = MockSyncService()
        vaultTimeoutService = MockVaultTimeoutService()
        clientVault.clientCiphers = clientCiphers
        stateService = MockStateService()

        subject = DefaultVaultRepository(
            cipherAPIService: APIService(client: client),
            cipherService: cipherService,
            clientAuth: clientAuth,
            clientCrypto: clientCrypto,
            clientVault: clientVault,
            collectionService: collectionService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            folderService: folderService,
            organizationService: organizationService,
            stateService: stateService,
            syncService: syncService,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        client = nil
        clientAuth = nil
        clientCiphers = nil
        clientCrypto = nil
        clientVault = nil
        collectionService = nil
        environmentService = nil
        errorReporter = nil
        folderService = nil
        organizationService = nil
        stateService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `addCipher()` makes the add cipher API request and updates the vault.
    func test_addCipher() async throws {
        let cipher = CipherView.fixture()
        try await subject.addCipher(cipher)

        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])

        XCTAssertEqual(cipherService.addCipherWithServerCiphers.last, Cipher(cipherView: cipher))
    }

    /// `addCipher()` throws an error if encrypting the cipher fails.
    func test_addCipher_encryptError() async {
        clientCiphers.encryptError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.addCipher(.fixture())
        }
    }

    /// `cipherPublisher()` returns a publisher for the list of a user's ciphers.
    func test_cipherPublisher() async throws {
        let ciphers: [Cipher] = [.fixture(name: "Bitwarden")]
        cipherService.ciphersSubject.value = ciphers

        var iterator = try await subject.cipherPublisher().makeAsyncIterator()
        let publishedCiphers = try await iterator.next()

        XCTAssertEqual(publishedCiphers, ciphers.map(CipherListView.init))
    }

    /// `ciphersAutofillPublisher(uri:)` returns a publisher for the list of a user's ciphers
    /// matching a URI.
    func test_ciphersAutofillPublisher() async throws {
        let ciphers: [Cipher] = [
            .fixture(
                id: "1",
                login: .fixture(uris: [LoginUri(uri: "https://bitwarden.com", match: .exact)]),
                name: "Bitwarden"
            ),
            .fixture(
                creationDate: Date(year: 2024, month: 1, day: 1),
                id: "2",
                login: .fixture(uris: [LoginUri(uri: "https://example.com", match: .exact)]),
                name: "Example",
                revisionDate: Date(year: 2024, month: 1, day: 1)
            ),
        ]
        cipherService.ciphersSubject.value = ciphers

        var iterator = try await subject.ciphersAutofillPublisher(
            uri: "https://example.com"
        ).makeAsyncIterator()
        let publishedCiphers = try await iterator.next()

        XCTAssertEqual(
            publishedCiphers,
            [
                .fixture(
                    creationDate: Date(year: 2024, month: 1, day: 1),
                    id: "2",
                    login: .fixture(uris: [LoginUriView(uri: "https://example.com", match: .exact)]),
                    name: "Example",
                    revisionDate: Date(year: 2024, month: 1, day: 1)
                ),
            ]
        )
    }

    /// `deleteCipher()` throws on id errors.
    func test_deleteCipher_idError_nil() async throws {
        cipherService.deleteWithServerResult = .failure(CipherAPIServiceError.updateMissingId)
        await assertAsyncThrows(error: CipherAPIServiceError.updateMissingId) {
            try await subject.deleteCipher("")
        }
    }

    /// `deleteCipher()` deletes cipher from back end and local storage.
    func test_deleteCipher() async throws {
        client.result = .httpSuccess(testData: APITestData(data: Data()))
        cipherService.deleteWithServerResult = .success(())
        try await subject.deleteCipher("123")
        XCTAssertEqual(cipherService.deleteCipherId, "123")
    }

    /// Tests the ability to determine if an account has premium.
    func test_doesActiveAccountHavePremium_error() async {
        stateService.activeAccount = nil

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.doesActiveAccountHavePremium()
        }
    }

    /// Tests the ability to determine if an account has premium.
    func test_doesActiveAccountHavePremium_false() async throws {
        stateService.activeAccount = .fixture(
            profile: .fixture(
                hasPremiumPersonally: false
            )
        )

        let hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertFalse(hasPremium)
    }

    /// Tests the ability to determine if an account has premium.
    func test_doesActiveAccountHavePremium_true() async throws {
        stateService.activeAccount = .fixture(
            profile: .fixture(
                hasPremiumPersonally: true
            )
        )

        let hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertTrue(hasPremium)
    }

    /// `fetchCipher(withId:)` returns the cipher if it exists and `nil` otherwise.
    func test_fetchCipher() async throws {
        var cipher = try await subject.fetchCipher(withId: "1")

        XCTAssertEqual(cipherService.fetchCipherId, "1")
        XCTAssertNil(cipher)

        let testCipher = Cipher.fixture(id: "2")
        cipherService.fetchCipherResult = .success(testCipher)

        cipher = try await subject.fetchCipher(withId: "2")

        XCTAssertEqual(cipherService.fetchCipherId, "2")
        XCTAssertEqual(cipher, CipherView(cipher: testCipher))
    }

    /// `fetchCipherOwnershipOptions()` returns the ownership options containing organizations.
    func test_fetchCipherOwnershipOptions_organizations() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(id: "1", name: "Org1"),
            .fixture(id: "2", name: "Org2"),
            .fixture(enabled: false, id: "3", name: "Org Disabled"),
            .fixture(id: "4", name: "Org Invited", status: .invited),
            .fixture(id: "5", name: "Org Accepted", status: .accepted),
        ])

        let ownershipOptions = try await subject.fetchCipherOwnershipOptions(includePersonal: true)

        XCTAssertEqual(
            ownershipOptions,
            [
                .personal(email: "user@bitwarden.com"),
                .organization(id: "1", name: "Org1"),
                .organization(id: "2", name: "Org2"),
            ]
        )
    }

    /// `fetchCipherOwnershipOptions()` returns the ownership options containing organizations
    /// without the personal vault.
    func test_fetchCipherOwnershipOptions_organizationsWithoutPersonal() async throws {
        stateService.activeAccount = .fixture()
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(id: "1", name: "Org1"),
            .fixture(id: "2", name: "Org2"),
            .fixture(enabled: false, id: "3", name: "Org Disabled"),
            .fixture(id: "4", name: "Org Invited", status: .invited),
            .fixture(id: "5", name: "Org Accepted", status: .accepted),
        ])

        let ownershipOptions = try await subject.fetchCipherOwnershipOptions(includePersonal: false)

        XCTAssertEqual(
            ownershipOptions,
            [
                .organization(id: "1", name: "Org1"),
                .organization(id: "2", name: "Org2"),
            ]
        )
    }

    /// `fetchCipherOwnershipOptions()` returns the ownership options containing the user's personal account.
    func test_fetchCipherOwnershipOptions_personal() async throws {
        stateService.activeAccount = .fixture()

        let ownershipOptions = try await subject.fetchCipherOwnershipOptions(includePersonal: true)

        XCTAssertEqual(ownershipOptions, [.personal(email: "user@bitwarden.com")])
    }

    /// `fetchCollections(includeReadOnly:)` returns the collections for the user.
    func test_fetchCollections() async throws {
        collectionService.fetchAllCollectionsResult = .success([
            .fixture(id: "1", name: "Collection 1"),
        ])
        let collections = try await subject.fetchCollections(includeReadOnly: false)

        XCTAssertEqual(
            collections,
            [
                .fixture(id: "1", name: "Collection 1"),
            ]
        )
        try XCTAssertFalse(XCTUnwrap(collectionService.fetchAllCollectionsIncludeReadOnly))
    }

    /// `fetchFolders` returns the folders for the user.
    func test_fetchFolders() async throws {
        let folders: [Folder] = [
            .fixture(id: "1", name: "Other Folder", revisionDate: Date(year: 2023, month: 12, day: 1)),
            .fixture(id: "2", name: "Folder", revisionDate: Date(year: 2023, month: 12, day: 2)),
        ]
        folderService.fetchAllFoldersResult = .success(folders)

        let fetchedFolders = try await subject.fetchFolders()

        XCTAssertEqual(
            fetchedFolders,
            [
                .fixture(id: "2", name: "Folder", revisionDate: Date(year: 2023, month: 12, day: 2)),
                .fixture(id: "1", name: "Other Folder", revisionDate: Date(year: 2023, month: 12, day: 1)),
            ]
        )
        XCTAssertEqual(clientVault.clientFolders.decryptedFolders, folders)
    }

    /// `fetchSync(isManualRefresh:)` only syncs when expected.
    func test_fetchSync() async throws {
        stateService.activeAccount = .fixture()

        // If it's not a manual refresh, it should sync.
        try await subject.fetchSync(isManualRefresh: false)
        XCTAssertTrue(syncService.didFetchSync)

        // If it's a manual refresh and the user has allowed sync on refresh,
        // it should sync.
        syncService.didFetchSync = false
        stateService.allowSyncOnRefresh["1"] = true
        try await subject.fetchSync(isManualRefresh: true)
        XCTAssertTrue(syncService.didFetchSync)

        // If it's a manual refresh and the user has not allowed sync on refresh,
        // it should not sync.
        syncService.didFetchSync = false
        stateService.allowSyncOnRefresh["1"] = false
        try await subject.fetchSync(isManualRefresh: true)
        XCTAssertFalse(syncService.didFetchSync)
    }

    /// `getDisableAutoTotpCopy()` gets the user's disable auto-copy TOTP value.
    func test_getDisableAutoTotpCopy() async throws {
        stateService.activeAccount = .fixture()
        stateService.disableAutoTotpCopyByUserId["1"] = false

        var isDisabled = try await subject.getDisableAutoTotpCopy()
        XCTAssertFalse(isDisabled)

        stateService.disableAutoTotpCopyByUserId["1"] = true
        isDisabled = try await subject.getDisableAutoTotpCopy()
        XCTAssertTrue(isDisabled)
    }

    /// `refreshTOTPCodes(:)` should not update non-totp items
    func test_refreshTOTPCodes_invalid_noKey() async throws {
        let newCode = "999232"
        clientVault.totpCode = newCode
        let totpModel = VaultListTOTP(
            id: "123",
            loginView: .fixture(),
            totpCode: .init(
                code: "123456",
                codeGenerationDate: Date(),
                period: 30
            )
        )
        let item: VaultListItem = .fixtureTOTP(totp: totpModel)
        let newItems = try await subject.refreshTOTPCodes(for: [item])
        let newItem = try XCTUnwrap(newItems.first)
        XCTAssertEqual(newItem, item)
    }

    /// `refreshTOTPCodes(:)` should not update non-totp items
    func test_refreshTOTPCodes_invalid_nonTOTP() async throws {
        let newCode = "999232"
        clientVault.totpCode = newCode
        let item: VaultListItem = .fixture()
        let newItems = try await subject.refreshTOTPCodes(for: [item])
        let newItem = try XCTUnwrap(newItems.first)
        XCTAssertEqual(newItem, item)
    }

    /// `refreshTOTPCodes(:)` should update correctly
    func test_refreshTOTPCodes_valid() async throws {
        let newCode = "999232"
        clientVault.totpCode = newCode
        let totpModel = VaultListTOTP(
            id: "123",
            loginView: .fixture(totp: .base32Key),
            totpCode: .init(
                code: "123456",
                codeGenerationDate: Date(),
                period: 30
            )
        )
        let item: VaultListItem = .fixtureTOTP(totp: totpModel)
        let newItems = try await subject.refreshTOTPCodes(for: [item])
        let newItem = try XCTUnwrap(newItems.first)
        switch newItem.itemType {
        case let .totp(_, model):
            XCTAssertEqual(model.id, totpModel.id)
            XCTAssertEqual(model.loginView, totpModel.loginView)
            XCTAssertNotEqual(model.totpCode.code, totpModel.totpCode.code)
            XCTAssertNotEqual(model.totpCode.codeGenerationDate, totpModel.totpCode.codeGenerationDate)
            XCTAssertEqual(model.totpCode.period, totpModel.totpCode.period)
            XCTAssertEqual(model.totpCode.code, newCode)
        default:
            XCTFail("Invalid return type")
        }
    }

    /// `searchCipherPublisher(searchText:, filterType:)` returns search matching cipher name.
    func test_searchCipherPublisher_searchText_name() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "dabcd"),
            .fixture(id: "2", name: "qwe"),
            .fixture(id: "3", name: "Café"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.last))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchCipherPublisher(searchText: "cafe", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchCipherPublisher(searchText:, filterType:)` returns search matching cipher name excludes items from trash.
    func test_searchCipherPublisher_searchText_excludesTrashedItems() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "dabcd"),
            .fixture(id: "2", name: "qwe"),
            .fixture(deletedDate: .now, id: "3", name: "deleted Café"),
            .fixture(id: "4", name: "Café"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.last))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchCipherPublisher(searchText: "cafe", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchCipherPublisher(searchText:, filterType:)` returns search matching cipher id.
    func test_searchCipherPublisher_searchText_id() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1223123", name: "dabcd"),
            .fixture(id: "31232131245435234", name: "qwe"),
            .fixture(id: "434343434", name: "Café"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[1]))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchCipherPublisher(searchText: "312321312", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchCipherPublisher(searchText:, filterType:)` returns search matching cipher uri.
    func test_searchCipherPublisher_searchText_uri() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "dabcd"),
            .fixture(id: "2", name: "qwe"),
            .fixture(
                id: "3",
                login: .init(
                    username: "name",
                    password: "pwd",
                    passwordRevisionDate: nil,
                    uris: [.init(uri: "www.domain.com", match: .domain)],
                    totp: nil,
                    autofillOnPageLoad: nil
                ),
                name: "Café"
            ),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.last))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchCipherPublisher(searchText: "domain", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchCipherPublisher(searchText:, filterType:)` only returns ciphers based on search text and VaultFilterType.
    func test_searchCipherPublisher_vaultType() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "bcd", organizationId: "testOrg"),
            .fixture(id: "2", name: "bcdew"),
            .fixture(id: "3", name: "dabcd"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.first))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchCipherPublisher(searchText: "bcd", filterType: .organization(.fixture(id: "testOrg")))
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `shareCipher()` has the cipher service share the cipher and updates the vault.
    func test_shareCipher() async throws {
        stateService.activeAccount = .fixtureAccountLogin()

        let cipher = CipherView.fixture()
        try await subject.shareCipher(cipher)

        XCTAssertEqual(cipherService.shareCipherWithServerCiphers, [Cipher(cipherView: cipher)])
        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])

        XCTAssertEqual(cipherService.shareCipherWithServerCiphers.last, Cipher(cipherView: cipher))
    }

    /// `updateCipherCollections()` throws an error if one occurs.
    func test_updateCipherCollections_error() async throws {
        cipherService.updateCipherCollectionsWithServerResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.updateCipherCollections(.fixture())
        }
    }

    /// `updateCipherCollections()` has the cipher service update the cipher's collections and updates the vault.
    func test_updateCipherCollections() async throws {
        stateService.activeAccount = .fixtureAccountLogin()

        let cipher = CipherView.fixture()
        try await subject.updateCipherCollections(cipher)

        XCTAssertEqual(cipherService.updateCipherCollectionsWithServerCiphers, [Cipher(cipherView: cipher)])
        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])
    }

    /// `updateCipher()` throws on encryption errors.
    func test_updateCipher_encryptError() async throws {
        clientCiphers.encryptError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.updateCipher(.fixture(id: "1"))
        }
    }

    /// `updateCipher()` makes the update cipher API request and updates the vault.
    func test_updateCipher() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: .cipherResponse)

        let cipher = CipherView.fixture(id: "123")
        try await subject.updateCipher(cipher)

        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])
    }

    /// `cipherDetailsPublisher(id:)` returns a publisher for the details of a cipher in the vault.
    func test_cipherDetailsPublisher() async throws {
        cipherService.ciphersSubject.send([.fixture(id: "123", name: "Apple")])

        var iterator = try await subject.cipherDetailsPublisher(id: "123")
            .makeAsyncIterator()
        let cipherDetails = try await iterator.next()

        XCTAssertEqual(cipherDetails??.name, "Apple")
    }

    /// `organizationsPublisher()` returns a publisher for the user's organizations.
    func test_organizationsPublisher() async throws {
        organizationService.organizationsSubject.value = [
            .fixture(id: "ORG_1", name: "ORG_NAME"),
            .fixture(id: "ORG_2", name: "ORG_NAME"),
        ]

        var iterator = try await subject.organizationsPublisher().makeAsyncIterator()
        let organizations = try await iterator.next()

        XCTAssertEqual(
            organizations,
            [
                Organization.fixture(id: "ORG_1", name: "ORG_NAME"),
                Organization.fixture(id: "ORG_2", name: "ORG_NAME"),
            ]
        )
    }

    /// `remove(userId:)` Removes an account id from the vault timeout service.
    func test_removeAccountId_success_unlocked() async {
        let account = Account.fixtureAccountLogin()
        vaultTimeoutService.timeoutStore = [
            account.profile.userId: false,
        ]
        await subject.remove(userId: account.profile.userId)
        XCTAssertEqual([:], vaultTimeoutService.timeoutStore)
    }

    /// `remove(userId:)` Removes an account id from the vault timeout service.
    func test_removeAccountId_success_locked() async {
        let account = Account.fixtureAccountLogin()
        vaultTimeoutService.timeoutStore = [
            account.profile.userId: true,
        ]
        await subject.remove(userId: account.profile.userId)
        XCTAssertEqual([:], vaultTimeoutService.timeoutStore)
    }

    /// `remove(userId:)` Throws no error when no account is found.
    func test_removeAccountId_failure() async {
        let account = Account.fixtureAccountLogin()
        vaultTimeoutService.timeoutStore = [
            account.profile.userId: false,
        ]
        await subject.remove(userId: "123")
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            vaultTimeoutService.timeoutStore
        )
    }

    /// `restoreCipher()` throws on id errors.
    func test_restoreCipher_idError_nil() async throws {
        stateService.accounts = [.fixtureAccountLogin()]
        stateService.activeAccount = .fixtureAccountLogin()
        await assertAsyncThrows(error: CipherAPIServiceError.updateMissingId) {
            try await subject.restoreCipher(.fixture(id: nil))
        }
    }

    /// `restoreCipher()` restores cipher for the back end and in local storage.
    func test_restoreCipher() async throws {
        client.result = .httpSuccess(testData: APITestData(data: Data()))
        stateService.accounts = [.fixtureAccountLogin()]
        stateService.activeAccount = .fixtureAccountLogin()
        let cipherView: CipherView = .fixture(deletedDate: .now, id: "123")
        cipherService.restoreWithServerResult = .success(())
        try await subject.restoreCipher(cipherView)
        XCTAssertNotNil(cipherView.deletedDate)
        XCTAssertNil(cipherService.restoredCipher?.deletedDate)
        XCTAssertEqual(cipherService.restoredCipherId, "123")
    }

    /// `softDeleteCipher()` throws on id errors.
    func test_softDeleteCipher_idError_nil() async throws {
        stateService.accounts = [.fixtureAccountLogin()]
        stateService.activeAccount = .fixtureAccountLogin()
        await assertAsyncThrows(error: CipherAPIServiceError.updateMissingId) {
            try await subject.softDeleteCipher(.fixture(id: nil))
        }
    }

    /// `softDeleteCipher()` deletes cipher from back end and local storage.
    func test_softDeleteCipher() async throws {
        client.result = .httpSuccess(testData: APITestData(data: Data()))
        stateService.accounts = [.fixtureAccountLogin()]
        stateService.activeAccount = .fixtureAccountLogin()
        let cipherView: CipherView = .fixture(id: "123")
        cipherService.softDeleteWithServerResult = .success(())
        try await subject.softDeleteCipher(cipherView)
        XCTAssertNil(cipherView.deletedDate)
        XCTAssertNotNil(cipherService.softDeleteCipher?.deletedDate)
        XCTAssertEqual(cipherService.softDeleteCipherId, "123")
    }

    /// `validatePassword(_:)` returns `true` if the master password matches the stored password hash.
    func test_validatePassword() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.masterPasswordHashes["1"] = "wxyz4321"
        clientAuth.validatePasswordResult = true

        let isValid = try await subject.validatePassword("test1234")

        XCTAssertTrue(isValid)
        XCTAssertEqual(clientAuth.validatePasswordPassword, "test1234")
        XCTAssertEqual(clientAuth.validatePasswordPasswordHash, "wxyz4321")
    }

    /// `validatePassword(_:)` returns `false` if there's no stored password hash.
    func test_validatePassword_noPasswordHash() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let isValid = try await subject.validatePassword("not the password")

        XCTAssertFalse(isValid)
    }

    /// `validatePassword(_:)` returns `false` if the master password doesn't match the stored password hash.
    func test_validatePassword_notValid() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.masterPasswordHashes["1"] = "wxyz4321"
        clientAuth.validatePasswordResult = false

        let isValid = try await subject.validatePassword("not the password")

        XCTAssertFalse(isValid)
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_card() async throws {
        let cipher = Cipher.fixture(id: "1", type: .card)
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .card, filter: .allVaults).makeAsyncIterator()
        let vaultListItems = try await iterator.next()

        XCTAssertEqual(vaultListItems, [.fixture(cipherView: .init(cipher: cipher))])
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_collection() async throws {
        let cipher = Cipher.fixture(collectionIds: ["1"], id: "1")
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .collection(id: "1", name: ""), filter: .allVaults)
            .makeAsyncIterator()
        let vaultListItems = try await iterator.next()

        XCTAssertEqual(vaultListItems, [.fixture(cipherView: .init(cipher: cipher))])
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_folder() async throws {
        let cipher = Cipher.fixture(folderId: "1", id: "1")
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .folder(id: "1", name: ""), filter: .allVaults)
            .makeAsyncIterator()
        let vaultListItems = try await iterator.next()

        XCTAssertEqual(vaultListItems, [.fixture(cipherView: .init(cipher: cipher))])
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_identity() async throws {
        let cipher = Cipher.fixture(id: "1", type: .identity)
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .identity, filter: .allVaults).makeAsyncIterator()
        let vaultListItems = try await iterator.next()

        XCTAssertEqual(vaultListItems, [.fixture(cipherView: .init(cipher: cipher))])
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_login() async throws {
        let cipher = Cipher.fixture(id: "1", type: .login)
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .login, filter: .allVaults).makeAsyncIterator()
        let vaultListItems = try await iterator.next()

        XCTAssertEqual(vaultListItems, [.fixture(cipherView: .init(cipher: cipher))])
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_secureNote() async throws {
        let cipher = Cipher.fixture(id: "1", type: .secureNote)
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .secureNote, filter: .allVaults).makeAsyncIterator()
        let vaultListItems = try await iterator.next()

        XCTAssertEqual(vaultListItems, [.fixture(cipherView: .init(cipher: cipher))])
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_totp() async throws {
        let cipher = Cipher.fixture(id: "1", login: .fixture(totp: "123"), type: .login)
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .totp, filter: .allVaults).makeAsyncIterator()
        let vaultListItems = try await iterator.next()

        let itemType = try XCTUnwrap(vaultListItems?.last?.itemType)
        if case let .totp(name, _) = itemType {
            XCTAssertEqual(name, "Bitwarden")
        } else {
            XCTFail("Totp item not found")
        }
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_trash() async throws {
        let cipher = Cipher.fixture(deletedDate: Date(), id: "1")
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .trash, filter: .allVaults).makeAsyncIterator()
        let vaultListItems = try await iterator.next()

        XCTAssertEqual(vaultListItems, [.fixture(cipherView: .init(cipher: cipher))])
    }

    /// `vaultListPublisher(filter:)` returns a publisher for the vault list sections.
    func test_vaultListPublisher_section() async throws { // swiftlint:disable:this function_body_length
        let ciphers: [Cipher] = [
            .fixture(folderId: "1", id: "1", type: .login),
            .fixture(id: "2", login: .fixture(totp: "123"), type: .login),
            .fixture(collectionIds: ["1"], favorite: true, id: "3"),
            .fixture(deletedDate: Date(), id: "3"),
        ]
        let collection = Collection.fixture(id: "1")
        let folder = Folder.fixture(id: "1")
        cipherService.ciphersSubject.send(ciphers)
        collectionService.collectionsSubject.send([collection])
        folderService.foldersSubject.send([folder])

        var iterator = try await subject.vaultListPublisher(filter: .allVaults).makeAsyncIterator()
        let vaultListSections = try await iterator.next()

        let expectedResult: [VaultListSection] = [
            .init(
                id: "TOTP",
                items: [.fixtureGroup(id: "Types.VerificationCodes", group: .totp, count: 1)],
                name: Localizations.totp
            ),
            .init(
                id: "Favorites",
                items: [.fixture(cipherView: .init(cipher: ciphers[2]))],
                name: Localizations.favorites
            ),
            .init(
                id: "Types",
                items: [
                    .fixtureGroup(id: "Types.Logins", group: .login, count: 3),
                    .fixtureGroup(id: "Types.Cards", group: .card, count: 0),
                    .fixtureGroup(id: "Types.Identities", group: .identity, count: 0),
                    .fixtureGroup(id: "Types.SecureNotes", group: .secureNote, count: 0),
                ],
                name: Localizations.types
            ),
            .init(
                id: "Folders",
                items: [.fixtureGroup(id: "1", group: .folder(id: "1", name: ""), count: 1)],
                name: Localizations.folders
            ),
            .init(
                id: "NoFolder",
                items: [
                    .fixture(cipherView: .init(cipher: ciphers[1])),
                    .fixture(cipherView: .init(cipher: ciphers[2])),
                ],
                name: Localizations.folderNone
            ),
            .init(
                id: "Collections",
                items: [.fixtureGroup(id: "1", group: .collection(id: "1", name: ""), count: 1)],
                name: Localizations.collections
            ),
            .init(
                id: "Trash",
                items: [.fixtureGroup(id: "Trash", group: .trash, count: 1)],
                name: Localizations.trash
            ),
        ]

        XCTAssertEqual(vaultListSections, expectedResult)
    }

    /// `vaultListPublisher(filter:)` records an error if the folder ids is nil.
    func test_vaultListPublisher_section_collectionError() async throws {
        let collection = Collection.fixture(id: nil)
        let folder = Folder.fixture(id: "1")
        cipherService.ciphersSubject.send([.fixture()])
        collectionService.collectionsSubject.send([collection])
        folderService.foldersSubject.send([folder])

        var iterator = try await subject.vaultListPublisher(filter: .allVaults).makeAsyncIterator()
        _ = try await iterator.next()

        XCTAssertEqual(
            errorReporter.errors.last as? NSError,
            BitwardenError.dataError("Received a collection from the API with a missing ID.")
        )
    }

    /// `vaultListPublisher(filter:)` records an error if the folder ids is nil.
    func test_vaultListPublisher_section_folderError() async throws {
        let collection = Collection.fixture(id: "1")
        let folder = Folder.fixture(id: nil)
        cipherService.ciphersSubject.send([.fixture()])
        collectionService.collectionsSubject.send([collection])
        folderService.foldersSubject.send([folder])

        var iterator = try await subject.vaultListPublisher(filter: .allVaults).makeAsyncIterator()
        _ = try await iterator.next()

        XCTAssertEqual(
            errorReporter.errors.last as? NSError,
            BitwardenError.dataError("Received a folder from the API with a missing ID.")
        )
    }

    /// `vaultListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the vault for a vault that contains collections with the my vault filter.
    func test_vaultListPublisher_withCollections_myVault() async throws {
        let syncResponse = try JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        )
        cipherService.ciphersSubject.send(syncResponse.ciphers.compactMap(Cipher.init))
        collectionService.collectionsSubject.send(syncResponse.collections.compactMap(Collection.init))
        folderService.foldersSubject.send(syncResponse.folders.compactMap(Folder.init))

        var iterator = try await subject.vaultListPublisher(filter: .myVault).makeAsyncIterator()
        let sections = try await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(sections)), as: .lines) {
            """
            Section: Types
              - Group: Login (1)
              - Group: Card (1)
              - Group: Identity (1)
              - Group: Secure note (1)
            Section: Folders
              - Group: Social (1)
            Section: No Folder
              - Cipher: Bitwarden User
              - Cipher: Top Secret Note
              - Cipher: Visa
            Section: Trash
              - Group: Trash (1)
            """
        }
    }

    /// `vaultListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the vault for a vault that contains collections with the organization filter.
    func test_vaultListPublisher_withCollections_organization() async throws {
        let syncResponse = try JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        )
        cipherService.ciphersSubject.send(syncResponse.ciphers.compactMap(Cipher.init))
        collectionService.collectionsSubject.send(syncResponse.collections.compactMap(Collection.init))
        folderService.foldersSubject.send(syncResponse.folders.compactMap(Folder.init))

        let organization = Organization.fixture(id: "ba756e34-4650-4e8a-8cbb-6e98bfae9abf")
        var iterator = try await subject.vaultListPublisher(filter: .organization(organization)).makeAsyncIterator()
        let sections = try await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(sections)), as: .lines) {
            """
            Section: Favorites
              - Cipher: Apple
            Section: Types
              - Group: Login (2)
              - Group: Card (0)
              - Group: Identity (0)
              - Group: Secure note (0)
            Section: No Folder
              - Cipher: Apple
              - Cipher: Figma
            Section: Collections
              - Group: Design (1)
              - Group: Engineering (1)
            Section: Trash
              - Group: Trash (0)
            """
        }
    }

    /// `vaultListPublisher(group:)` returns a publisher for a group of login items within the vault list.
    func test_vaultListPublisher_forGroup_login() async throws {
        let syncResponse = try JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        )
        cipherService.ciphersSubject.send(syncResponse.ciphers.compactMap(Cipher.init))

        var iterator = try await subject.vaultListPublisher(group: .login, filter: .allVaults).makeAsyncIterator()
        let items = try await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListItems(XCTUnwrap(items)), as: .lines) {
            """
            - Cipher: Apple
            - Cipher: Facebook
            - Cipher: Figma
            """
        }
    }

    /// `vaultListPublisher(group:)` returns a publisher for a group of login items within the vault
    /// list filtered by the user's vault.
    func test_vaultListPublisher_forGroup_login_myVault() async throws {
        let syncResponse = try JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        )
        cipherService.ciphersSubject.send(syncResponse.ciphers.compactMap(Cipher.init))

        var iterator = try await subject.vaultListPublisher(group: .login, filter: .myVault).makeAsyncIterator()
        let items = try await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListItems(XCTUnwrap(items)), as: .lines) {
            """
            - Cipher: Facebook
            """
        }
    }

    /// `vaultListPublisher(group:)` returns a publisher for a group of login items within the vault
    /// list filtered by an organization.
    func test_vaultListPublisher_forGroup_login_organization() async throws {
        let syncResponse = try JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        )
        cipherService.ciphersSubject.send(syncResponse.ciphers.compactMap(Cipher.init))

        var iterator = try await subject.vaultListPublisher(
            group: .login,
            filter: .organization(.fixture(id: "ba756e34-4650-4e8a-8cbb-6e98bfae9abf"))
        ).makeAsyncIterator()
        let items = try await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListItems(XCTUnwrap(items)), as: .lines) {
            """
            - Cipher: Apple
            - Cipher: Figma
            """
        }
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for a group of items in a collection within
    /// the vault list.
    func test_vaultListPublisher_forGroup_collection() async throws {
        let syncResponse = try JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        )
        cipherService.ciphersSubject.send(syncResponse.ciphers.compactMap(Cipher.init))

        var iterator = try await subject.vaultListPublisher(
            group: .collection(id: "f96de98e-618a-4886-b396-66b92a385325", name: "Engineering"),
            filter: .allVaults
        ).makeAsyncIterator()
        let items = try await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListItems(XCTUnwrap(items)), as: .lines) {
            """
            - Cipher: Apple
            """
        }
    }

    // MARK: Private

    /// Returns a string containing a description of the vault list items.
    func dumpVaultListItems(_ items: [VaultListItem], indent: String = "") -> String {
        guard !items.isEmpty else { return indent + "(empty)" }
        return items.reduce(into: "") { result, item in
            switch item.itemType {
            case let .cipher(cipher):
                result.append(indent + "- Cipher: \(cipher.name)")
            case let .group(group, count):
                result.append(indent + "- Group: \(group.name) (\(count))")
            case let .totp(name, model):
                result.append(indent + "- TOTP: \(model.id) \(name) \(model.totpCode.displayCode)")
            }
            if item != items.last {
                result.append("\n")
            }
        }
    }

    /// Returns a string containing a description of the vault list sections.
    func dumpVaultListSections(_ sections: [VaultListSection]) -> String {
        sections.reduce(into: "") { result, section in
            result.append("Section: \(section.name)\n")
            result.append(dumpVaultListItems(section.items, indent: "  "))
            if section != sections.last {
                result.append("\n")
            }
        }
    }
} // swiftlint:disable:this file_length
