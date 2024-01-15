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
        stateService.activeAccount = .fixtureAccountLogin()
        client.results = [
            .httpSuccess(testData: .cipherResponse),
            .httpSuccess(testData: .syncWithCipher),
        ]

        let cipher = CipherView.fixture()
        try await subject.addCipher(cipher)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers")

        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])
        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `addCipher()` makes the add cipher API request for a cipher with collections and updates the vault.
    func test_addCipher_withCollections() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        client.results = [
            .httpSuccess(testData: .cipherResponse),
            .httpSuccess(testData: .syncWithCipher),
        ]

        let cipher = CipherView.fixture(collectionIds: ["1", "2", "3"])
        try await subject.addCipher(cipher)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/create")

        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])
        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `addCipher()` throws an error if encrypting the cipher fails.
    func test_addCipher_encryptError() async {
        struct EncryptError: Error, Equatable {}

        clientCiphers.encryptError = EncryptError()

        await assertAsyncThrows(error: EncryptError()) {
            try await subject.addCipher(.fixture())
        }
    }

    /// `cipherPublisher()` returns a publisher for the list of a user's ciphers.
    func test_cipherPublisher() async throws {
        let ciphers: [Cipher] = [
            .fixture(name: "Bitwarden"),
        ]
        cipherService.ciphersSubject.value = ciphers

        var iterator = try await subject.cipherPublisher().makeAsyncIterator()
        let publishedCiphers = try await iterator.next()

        XCTAssertEqual(publishedCiphers, ciphers.map(CipherListView.init))
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

    /// `searchCipherPublisher(searchText:, filterType:)` throws an `.noActiveAccount` error.
    func test_searchCipherPublisher_accountError() async throws {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.searchCipherPublisher(searchText: "abc", filterType: .allVaults)
        }
    }

    /// `searchCipherPublisher(searchText:, filterType:)` returns search matching cipher name.
    func test_searchCipherPublisher_searchText_name() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.cipherSubject.value = [
            .fixture(id: "1", name: "dabcd"),
            .fixture(id: "2", name: "qwe"),
            .fixture(id: "3", name: "Café"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.cipherSubject.value.last))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchCipherPublisher(searchText: "cafe", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(cipherService.cipherPublisherUserId, Account.fixtureAccountLogin().profile.userId)
        XCTAssertEqual(
            ciphers,
            expectedSearchResult
        )
    }

    /// `searchCipherPublisher(searchText:, filterType:)` returns search matching cipher name excludes items from trash.
    func test_searchCipherPublisher_searchText_excludesTrashedItems() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.cipherSubject.value = [
            .fixture(id: "1", name: "dabcd"),
            .fixture(id: "2", name: "qwe"),
            .fixture(deletedDate: .now, id: "3", name: "deleted Café"),
            .fixture(id: "4", name: "Café"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.cipherSubject.value.last))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchCipherPublisher(searchText: "cafe", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(cipherService.cipherPublisherUserId, Account.fixtureAccountLogin().profile.userId)
        XCTAssertEqual(
            ciphers,
            expectedSearchResult
        )
    }

    /// `searchCipherPublisher(searchText:, filterType:)` returns search matching cipher id.
    func test_searchCipherPublisher_searchText_id() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.cipherSubject.value = [
            .fixture(id: "1223123", name: "dabcd"),
            .fixture(id: "31232131245435234", name: "qwe"),
            .fixture(id: "434343434", name: "Café"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.cipherSubject.value[1]))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchCipherPublisher(searchText: "312321312", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(cipherService.cipherPublisherUserId, Account.fixtureAccountLogin().profile.userId)
        XCTAssertEqual(
            ciphers,
            expectedSearchResult
        )
    }

    /// `searchCipherPublisher(searchText:, filterType:)` returns search matching cipher uri.
    func test_searchCipherPublisher_searchText_uri() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.cipherSubject.value = [
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
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.cipherSubject.value.last))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchCipherPublisher(searchText: "domain", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(cipherService.cipherPublisherUserId, Account.fixtureAccountLogin().profile.userId)
        XCTAssertEqual(
            ciphers,
            expectedSearchResult
        )
    }

    /// `searchCipherPublisher(searchText:, filterType:)` only returns ciphers based on search text and VaultFilterType.
    func test_searchCipherPublisher_vaultType() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.cipherSubject.value = [
            .fixture(id: "1", name: "bcd", organizationId: "testOrg"),
            .fixture(id: "2", name: "bcdew"),
            .fixture(id: "3", name: "dabcd"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.cipherSubject.value.first))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchCipherPublisher(searchText: "bcd", filterType: .organization(.fixture(id: "testOrg")))
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(cipherService.cipherPublisherUserId, Account.fixtureAccountLogin().profile.userId)
        XCTAssertEqual(
            ciphers,
            expectedSearchResult
        )
    }

    /// `shareCipher()` has the cipher service share the cipher and updates the vault.
    func test_shareCipher() async throws {
        stateService.activeAccount = .fixtureAccountLogin()

        let cipher = CipherView.fixture()
        try await subject.shareCipher(cipher)

        XCTAssertEqual(cipherService.shareWithServerCiphers, [Cipher(cipherView: cipher)])
        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])
        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `updateCipherCollections()` throws an error if one occurs.
    func test_updateCipherCollections_error() async throws {
        struct UpdateError: Error, Equatable {}

        cipherService.updateCipherCollectionsWithServerResult = .failure(UpdateError())

        await assertAsyncThrows(error: UpdateError()) {
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
        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `shareCipher()` throws an error if one occurs.
    func test_shareCipher_error() async throws {
        struct ShareError: Error, Equatable {}

        cipherService.shareWithServerResult = .failure(ShareError())

        await assertAsyncThrows(error: ShareError()) {
            try await subject.shareCipher(.fixture())
        }
    }

    /// `updateCipher()` throws on encryption errors.
    func test_updateCipher_encryptError() async throws {
        struct EncryptError: Error, Equatable {}

        clientCiphers.encryptError = EncryptError()

        await assertAsyncThrows(error: EncryptError()) {
            try await subject.updateCipher(.fixture(id: "1"))
        }
    }

    /// `updateCipher()` throws on id errors.
    func test_updateCipher_idError_nil() async throws {
        await assertAsyncThrows(error: CipherAPIServiceError.updateMissingId) {
            try await subject.updateCipher(.fixture(id: nil))
        }
    }

    /// `updateCipher()` throws on id errors.
    func test_updateCipher_idError_empty() async throws {
        await assertAsyncThrows(error: CipherAPIServiceError.updateMissingId) {
            try await subject.updateCipher(.fixture(id: ""))
        }
    }

    /// `updateCipher()` makes the update cipher API request and updates the vault.
    func test_updateCipher() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: .cipherResponse)

        let cipher = CipherView.fixture(id: "123")
        try await subject.updateCipher(cipher)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/123")

        XCTAssertEqual(clientCiphers.encryptedCiphers, [cipher])
        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `cipherDetailsPublisher(id:)` returns a publisher for the details of a cipher in the vault.
    func test_cipherDetailsPublisher() async throws {
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphers.data
        ))

        var iterator = subject.cipherDetailsPublisher(id: "fdabf83f-f1c0-4703-894d-4c0fd6741a9a").makeAsyncIterator()
        let cipherDetails = await iterator.next()

        XCTAssertEqual(cipherDetails?.name, "Apple")
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

    /// `vaultListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the vault.
    func test_vaultListPublisher() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphers.data
        ))

        var iterator = subject.vaultListPublisher(filter: .allVaults).makeAsyncIterator()
        let sections = await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(sections)), as: .lines) {
            """
            Section: TOTP
              - Group: Verification codes (1)
            Section: Favorites
              - Cipher: Apple
            Section: Types
              - Group: Login (2)
              - Group: Card (1)
              - Group: Identity (1)
              - Group: Secure note (1)
            Section: Folders
              - Group: Social (1)
            Section: No Folder
              - Cipher: Apple
              - Cipher: Bitwarden User
              - Cipher: Top Secret Note
              - Cipher: Visa
            Section: Trash
              - Group: Trash (1)
            """
        }
    }

    /// `vaultListPublisher()` returns a publisher which publishes an empty array if the user's
    /// vault contains no ciphers.
    func test_vaultListPublisher_empty() async throws {
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithProfile.data
        ))

        var iterator = subject.vaultListPublisher(filter: .allVaults).makeAsyncIterator()
        let sections = await iterator.next()

        try XCTAssertTrue(XCTUnwrap(sections).isEmpty)
    }

    /// `vaultListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the vault for a vault that contains collections.
    func test_vaultListPublisher_withCollections() async throws {
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        ))

        var iterator = subject.vaultListPublisher(filter: .allVaults).makeAsyncIterator()
        let sections = await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(sections)), as: .lines) {
            """
            Section: Favorites
              - Cipher: Apple
            Section: Types
              - Group: Login (3)
              - Group: Card (1)
              - Group: Identity (1)
              - Group: Secure note (1)
            Section: Folders
              - Group: Social (1)
            Section: No Folder
              - Cipher: Apple
              - Cipher: Bitwarden User
              - Cipher: Figma
              - Cipher: Top Secret Note
              - Cipher: Visa
            Section: Collections
              - Group: Design (1)
              - Group: Engineering (1)
            Section: Trash
              - Group: Trash (1)
            """
        }
    }

    /// `vaultListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the vault for a vault that contains collections with the my vault filter.
    func test_vaultListPublisher_withCollections_myVault() async throws {
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        ))

        var iterator = subject.vaultListPublisher(filter: .myVault).makeAsyncIterator()
        let sections = await iterator.next()

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
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        ))

        let organization = Organization.fixture(id: "ba756e34-4650-4e8a-8cbb-6e98bfae9abf")
        var iterator = subject.vaultListPublisher(filter: .organization(organization)).makeAsyncIterator()
        let sections = await iterator.next()

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
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphers.data
        ))

        var iterator = subject.vaultListPublisher(group: .login, filter: .allVaults).makeAsyncIterator()
        let items = await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListItems(XCTUnwrap(items)), as: .lines) {
            """
            - Cipher: Apple
            - Cipher: Facebook
            """
        }
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for a group of items in a collection within
    /// the vault list.
    func test_vaultListPublisher_forGroup_collection() async throws {
        try syncService.syncSubject.send(JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        ))

        var iterator = subject.vaultListPublisher(
            group: .collection(id: "f96de98e-618a-4886-b396-66b92a385325", name: "Engineering"),
            filter: .allVaults
        ).makeAsyncIterator()
        let items = await iterator.next()

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
