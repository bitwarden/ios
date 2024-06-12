import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var cipherService: MockCipherService!
    var client: MockHTTPClient!
    var clientCiphers: MockClientCiphers!
    var clientService: MockClientService!
    var collectionService: MockCollectionService!
    var configService: MockConfigService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var folderService: MockFolderService!
    var nonPremiumAccount = Account.fixture(profile: .fixture(hasPremiumPersonally: false))
    var now: Date!
    var premiumAccount = Account.fixture(profile: .fixture(hasPremiumPersonally: true))
    var organizationService: MockOrganizationService!
    var stateService: MockStateService!
    var subject: DefaultVaultRepository!
    var syncService: MockSyncService!
    var timeProvider: MockTimeProvider!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        client = MockHTTPClient()
        clientCiphers = MockClientCiphers()
        clientService = MockClientService()
        collectionService = MockCollectionService()
        configService = MockConfigService()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        folderService = MockFolderService()
        now = Date(year: 2024, month: 1, day: 18)
        organizationService = MockOrganizationService()
        syncService = MockSyncService()
        timeProvider = MockTimeProvider(.mockTime(now))
        vaultTimeoutService = MockVaultTimeoutService()
        clientService.mockVault.clientCiphers = clientCiphers
        stateService = MockStateService()

        subject = DefaultVaultRepository(
            cipherService: cipherService,
            clientService: clientService,
            collectionService: collectionService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            folderService: folderService,
            organizationService: organizationService,
            settingsService: MockSettingsService(),
            stateService: stateService,
            syncService: syncService,
            timeProvider: timeProvider,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        client = nil
        clientCiphers = nil
        clientService = nil
        collectionService = nil
        configService = nil
        environmentService = nil
        errorReporter = nil
        folderService = nil
        organizationService = nil
        now = nil
        stateService = nil
        subject = nil
        timeProvider = nil
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
                login: .fixture(uris: [.fixture(uri: "https://bitwarden.com", match: .exact)]),
                name: "Bitwarden"
            ),
            .fixture(
                creationDate: Date(year: 2024, month: 1, day: 1),
                id: "2",
                login: .fixture(uris: [.fixture(uri: "https://example.com", match: .exact)]),
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
                    login: .fixture(uris: [.fixture(uri: "https://example.com", match: .exact)]),
                    name: "Example",
                    revisionDate: Date(year: 2024, month: 1, day: 1)
                ),
            ]
        )
    }

    /// `deleteCipher()` throws on id errors.
    func test_deleteCipher_idError_nil() async throws {
        cipherService.deleteCipherWithServerResult = .failure(CipherAPIServiceError.updateMissingId)
        await assertAsyncThrows(error: CipherAPIServiceError.updateMissingId) {
            try await subject.deleteCipher("")
        }
    }

    /// `deleteAttachment(withId:cipherId)` deletes attachment from backend and local storage.
    func test_deleteAttachment() async throws {
        cipherService.deleteAttachmentWithServerResult = .success(.fixture(id: "2"))

        let updatedCipher = try await subject.deleteAttachment(withId: "10", cipherId: "")

        XCTAssertEqual(cipherService.deleteAttachmentWithServerAttachmentId, "10")
        XCTAssertEqual(updatedCipher, CipherView(cipher: .fixture(id: "2")))
    }

    /// `deleteAttachment(withId:cipherId)` returns nil if the cipher couldn't be found for some reason.
    func test_deleteAttachment_nilResult() async throws {
        cipherService.deleteAttachmentWithServerResult = .success(nil)

        let updatedCipher = try await subject.deleteAttachment(withId: "10", cipherId: "")

        XCTAssertEqual(cipherService.deleteAttachmentWithServerAttachmentId, "10")
        XCTAssertNil(updatedCipher)
    }

    /// `deleteCipher()` deletes cipher from backend and local storage.
    func test_deleteCipher() async throws {
        cipherService.deleteCipherWithServerResult = .success(())
        try await subject.deleteCipher("123")
        XCTAssertEqual(cipherService.deleteCipherId, "123")
    }

    /// `doesActiveAccountHavePremium()` returns whether the active account has access to premium features.
    func test_doesActiveAccountHavePremium() async throws {
        stateService.doesActiveAccountHavePremiumResult = .success(true)
        var hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertTrue(hasPremium)

        stateService.doesActiveAccountHavePremiumResult = .success(false)
        hasPremium = try await subject.doesActiveAccountHavePremium()
        XCTAssertFalse(hasPremium)
    }

    /// `downloadAttachment(_:cipher:)` downloads the attachment data and saves the result to the documents directory.
    func test_downloadAttachment() async throws {
        // Set up the mock data.
        stateService.activeAccount = .fixture()
        let downloadUrl = FileManager.default.temporaryDirectory.appendingPathComponent("sillyGoose.txt")
        try Data("🪿".utf8).write(to: downloadUrl)
        cipherService.downloadAttachmentResult = .success(downloadUrl)
        let attachment = AttachmentView.fixture(fileName: "sillyGoose.txt")
        let cipher = CipherView.fixture(attachments: [attachment])

        // Test.
        let resultUrl = try await subject.downloadAttachment(attachment, cipher: cipher)

        // Confirm the results.
        XCTAssertEqual(clientService.mockVault.clientCiphers.encryptedCiphers.last, cipher)
        XCTAssertEqual(cipherService.downloadAttachmentId, attachment.id)
        XCTAssertEqual(clientService.mockVault.clientAttachments.encryptedFilePaths.last, downloadUrl.path)
        XCTAssertEqual(resultUrl?.lastPathComponent, "sillyGoose.txt")
    }

    /// `downloadAttachment(_:cipher:)` throws an error for nil id's.
    func test_downloadAttachment_nilId() async throws {
        await assertAsyncThrows {
            _ = try await subject.downloadAttachment(.fixture(id: nil), cipher: .fixture(id: nil))
        }
    }

    /// `downloadAttachment(_:cipher:)` updates the cipher on the server if the SDK adds a cipher key.
    func test_downloadAttachment_updatesMigratedCipher() async throws {
        stateService.activeAccount = .fixture()
        let downloadUrl = FileManager.default.temporaryDirectory.appendingPathComponent("sillyGoose.txt")
        try Data("🪿".utf8).write(to: downloadUrl)
        cipherService.downloadAttachmentResult = .success(downloadUrl)
        let attachment = AttachmentView.fixture(fileName: "sillyGoose.txt")
        let cipherView = CipherView.fixture(attachments: [attachment])
        let cipher = Cipher.fixture(
            attachments: [Attachment(attachmentView: attachment)],
            key: "new key"
        )
        clientCiphers.encryptCipherResult = .success(cipher)

        let resultUrl = try await subject.downloadAttachment(attachment, cipher: cipherView)

        XCTAssertEqual(clientService.mockVault.clientCiphers.encryptedCiphers.last, cipherView)
        XCTAssertEqual(cipherService.downloadAttachmentId, attachment.id)
        XCTAssertEqual(clientService.mockVault.clientAttachments.encryptedFilePaths.last, downloadUrl.path)
        XCTAssertEqual(cipherService.updateCipherWithServerCiphers, [cipher])
        XCTAssertEqual(resultUrl?.lastPathComponent, "sillyGoose.txt")
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
        XCTAssertEqual(clientService.mockVault.clientFolders.decryptedFolders, folders)
    }

    /// `fetchSync(isManualRefresh:)` only syncs when expected.
    func test_fetchSync() async throws {
        stateService.activeAccount = .fixture()

        // If it's not a manual refresh, it should sync.
        let automaticSections = try await subject.fetchSync(
            isManualRefresh: false,
            filter: .allVaults
        )
        XCTAssertTrue(syncService.didFetchSync)
        XCTAssertNotNil(automaticSections)

        // If it's a manual refresh and the user has allowed sync on refresh,
        // it should sync.
        syncService.didFetchSync = false
        stateService.allowSyncOnRefresh["1"] = true
        let manualSections = try await subject.fetchSync(
            isManualRefresh: true,
            filter: .myVault
        )
        XCTAssertTrue(syncService.didFetchSync)
        XCTAssertNotNil(manualSections)

        // If it's a manual refresh and the user has not allowed sync on refresh,
        // it should not sync.
        syncService.didFetchSync = false
        stateService.allowSyncOnRefresh["1"] = false
        let nilSections = try await subject.fetchSync(isManualRefresh: true, filter: .allVaults)
        XCTAssertFalse(syncService.didFetchSync)
        XCTAssertNil(nilSections)
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

    /// `refreshTOTPCode(:)` rethrows errors.
    func test_refreshTOTPCode_error() async throws {
        clientService.mockVault.generateTOTPCodeResult = .failure(BitwardenTestError.example)
        let keyModel = try XCTUnwrap(TOTPKeyModel(authenticatorKey: .base32Key))
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.refreshTOTPCode(for: keyModel)
        }
    }

    /// `refreshTOTPCode(:)` creates a LoginTOTP model on success.
    func test_refreshTOTPCode_success() async throws {
        let newCode = "999232"
        clientService.mockVault.generateTOTPCodeResult = .success(newCode)
        let keyModel = try XCTUnwrap(TOTPKeyModel(authenticatorKey: .base32Key))
        let update = try await subject.refreshTOTPCode(for: keyModel)
        XCTAssertEqual(
            update,
            LoginTOTPState(
                authKeyModel: keyModel,
                codeModel: .init(
                    code: newCode,
                    codeGenerationDate: timeProvider.presentTime,
                    period: UInt32(keyModel.period)
                )
            )
        )
    }

    /// `refreshTOTPCodes(:)` should not update non-totp items
    func test_refreshTOTPCodes_invalid_noKey() async throws {
        let newCode = "999232"
        clientService.mockVault.generateTOTPCodeResult = .success(newCode)
        let totpModel = VaultListTOTP(
            id: "123",
            loginView: .fixture(),
            requiresMasterPassword: false,
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
        clientService.mockVault.generateTOTPCodeResult = .success(newCode)
        let item: VaultListItem = .fixture()
        let newItems = try await subject.refreshTOTPCodes(for: [item])
        let newItem = try XCTUnwrap(newItems.first)
        XCTAssertEqual(newItem, item)
    }

    /// `refreshTOTPCodes(:)` should update correctly
    func test_refreshTOTPCodes_valid() async throws {
        let newCode = "999232"
        clientService.mockVault.generateTOTPCodeResult = .success(newCode)
        let totpModel = VaultListTOTP(
            id: "123",
            loginView: .fixture(totp: .base32Key),
            requiresMasterPassword: false,
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

    /// `searchCipherAutofillPublisher(searchText:filterType:)` returns search matching cipher name.
    func test_searchCipherAutofillPublisher_searchText_name() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "dabcd", type: .login),
            .fixture(id: "2", name: "qwe", type: .login),
            .fixture(id: "3", name: "Café", type: .login),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.last))
        var iterator = try await subject
            .searchCipherAutofillPublisher(searchText: "cafe", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, [cipherView])
    }

    /// `searchCipherAutofillPublisher(searchText:filterType:)` returns matching ciphers excludes
    /// items from trash.
    func test_searchCipherAutofillPublisher_searchText_excludesTrashedItems() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "dabcd"),
            .fixture(id: "2", name: "qwe"),
            .fixture(deletedDate: .now, id: "3", name: "deleted Café"),
            .fixture(id: "4", name: "Café"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.last))
        var iterator = try await subject
            .searchCipherAutofillPublisher(searchText: "cafe", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, [cipherView])
    }

    /// `searchCipherAutofillPublisher(searchText:filterType:)` returns search matching cipher id.
    func test_searchCipherAutofillPublisher_searchText_id() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1223123", name: "dabcd"),
            .fixture(id: "31232131245435234", name: "qwe"),
            .fixture(id: "434343434", name: "Café"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[1]))
        var iterator = try await subject
            .searchCipherAutofillPublisher(searchText: "312321312", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, [cipherView])
    }

    /// `searchCipherAutofillPublisher(searchText:filterType:)` returns matching ciphers and only
    /// includes login items.
    func test_searchCipherAutofillPublisher_searchText_includesOnlyLogins() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "Café", type: .card),
            .fixture(id: "2", name: "Café", type: .identity),
            .fixture(id: "4", name: "Café", type: .secureNote),
            .fixture(id: "3", name: "Café", type: .login),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.last))
        var iterator = try await subject
            .searchCipherAutofillPublisher(searchText: "cafe", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, [cipherView])
    }

    /// `searchCipherAutofillPublisher(searchText:, filterType:)` returns search matching cipher URI.
    func test_searchCipherAutofillPublisher_searchText_uri() async throws {
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
                    uris: [.fixture(uri: "www.domain.com", match: .domain)],
                    totp: nil,
                    autofillOnPageLoad: nil,
                    fido2Credentials: nil
                ),
                name: "Café"
            ),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.last))
        var iterator = try await subject
            .searchCipherAutofillPublisher(searchText: "domain", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, [cipherView])
    }

    /// `searchCipherAutofillPublisher(searchText,filterType:)` only returns ciphers based on
    /// search text and VaultFilterType.
    func test_searchCipherAutofillPublisher_vaultType() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "bcd", organizationId: "testOrg"),
            .fixture(id: "2", name: "bcdew"),
            .fixture(id: "3", name: "dabcd"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.first))
        var iterator = try await subject
            .searchCipherAutofillPublisher(searchText: "bcd", filterType: .organization(.fixture(id: "testOrg")))
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, [cipherView])
    }

    /// `searchVaultListPublisher(searchText:, filterType:)` returns search matching cipher name.
    func test_searchVaultListPublisher_searchText_name() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "dabcd"),
            .fixture(id: "2", name: "qwe"),
            .fixture(id: "3", name: "Café"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.last))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchVaultListPublisher(searchText: "cafe", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchVaultListPublisher(searchText:, filterType:)` returns search matching cipher name
    /// excludes items from trash.
    func test_searchVaultListPublisher_searchText_excludesTrashedItems() async throws {
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
            .searchVaultListPublisher(searchText: "cafe", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchVaultListPublisher(searchText:, group: .trash, filterType:)`
    /// returns only matching items form the trash.
    func test_searchVaultListPublisher_searchText_trashGroup() async throws {
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "dabcd"),
            .fixture(id: "2", name: "qwe"),
            .fixture(deletedDate: .now, id: "3", name: "deleted Café"),
            .fixture(id: "4", name: "Café"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[2]))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchVaultListPublisher(
                searchText: "cafe",
                group: .trash,
                filterType: .allVaults
            )
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchVaultListPublisher(searchText:, group: .card, filterType:)`
    /// returns search results with card items matching a name.
    func test_searchVaultListPublisher_searchText_cardGroup() async throws {
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "café", type: .card),
            .fixture(id: "2", name: "cafepass", type: .login),
            .fixture(deletedDate: .now, id: "3", name: "deleted Café"),
            .fixture(id: "4", name: "Café Friend", type: .identity),
            .fixture(id: "5", name: "Café thoughts", type: .secureNote),
            .fixture(
                id: "5",
                login: .fixture(totp: .base32Key),
                name: "one time cafefe",
                type: .login
            ),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[0]))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchVaultListPublisher(
                searchText: "cafe",
                group: .card,
                filterType: .allVaults
            )
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchVaultListPublisher(searchText:, group: .card, filterType:)`
    /// returns search items matching a cipher name within a folder.
    func test_searchVaultListPublisher_searchText_folderGroup() async throws {
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "café", type: .card),
            .fixture(id: "2", name: "cafepass", type: .login),
            .fixture(deletedDate: .now, id: "3", name: "deleted Café"),
            .fixture(
                folderId: "coffee",
                id: "0",
                name: "Best Cafes",
                type: .secureNote
            ),
            .fixture(id: "4", name: "Café Friend", type: .identity),
            .fixture(id: "5", name: "Café thoughts", type: .secureNote),
            .fixture(
                id: "5",
                login: .fixture(totp: .base32Key),
                name: "one time cafefe",
                type: .login
            ),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[3]))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchVaultListPublisher(
                searchText: "cafe",
                group: .folder(id: "coffee", name: "Caff-fiend"),
                filterType: .allVaults
            )
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchVaultListPublisher(searchText:, group: .collection, filterType:)`
    /// returns search items matching a cipher name within collections.
    func test_searchVaultListPublisher_searchText_collection() async throws {
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "café", type: .card),
            .fixture(id: "2", name: "cafepass", type: .login),
            .fixture(deletedDate: .now, id: "3", name: "deleted Café"),
            .fixture(
                folderId: "coffee",
                id: "0",
                name: "Best Cafes",
                type: .secureNote
            ),
            .fixture(
                collectionIds: ["123", "meep"],
                id: "4",
                name: "Café Friend",
                type: .identity
            ),
            .fixture(id: "5", name: "Café thoughts", type: .secureNote),
            .fixture(
                id: "5",
                login: .fixture(totp: .base32Key),
                name: "one time cafefe",
                type: .login
            ),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[4]))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchVaultListPublisher(
                searchText: "cafe",
                group: .collection(
                    id: "123",
                    name: "The beans",
                    organizationId: "Giv-em-da-beanz"
                ),
                filterType: .allVaults
            )
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchVaultListPublisher(searchText:, group: .identity, filterType:)`
    /// returns search matching cipher name for identities.
    func test_searchVaultListPublisher_searchText_identity() async throws {
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "café", type: .card),
            .fixture(id: "2", name: "cafepass", type: .login),
            .fixture(deletedDate: .now, id: "3", name: "deleted Café"),
            .fixture(
                folderId: "coffee",
                id: "0",
                name: "Best Cafes",
                type: .secureNote
            ),
            .fixture(
                collectionIds: ["123", "meep"],
                id: "4",
                name: "Café Friend",
                type: .identity
            ),
            .fixture(id: "5", name: "Café thoughts", type: .secureNote),
            .fixture(
                id: "5",
                login: .fixture(totp: .base32Key),
                name: "one time cafefe",
                type: .login
            ),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[4]))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchVaultListPublisher(
                searchText: "cafe",
                group: .identity,
                filterType: .allVaults
            )
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchVaultListPublisher(searchText:, group: .login, filterType:)`
    /// returns search matching cipher name for login items.
    func test_searchVaultListPublisher_searchText_login() async throws {
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "café", type: .card),
            .fixture(id: "2", name: "cafepass", type: .login),
            .fixture(deletedDate: .now, id: "3", name: "deleted Café"),
            .fixture(
                folderId: "coffee",
                id: "0",
                name: "Best Cafes",
                type: .secureNote
            ),
            .fixture(
                collectionIds: ["123", "meep"],
                id: "4",
                name: "Café Friend",
                type: .identity
            ),
            .fixture(id: "5", name: "Café thoughts", type: .secureNote),
            .fixture(
                id: "6",
                login: .fixture(totp: .base32Key),
                name: "one time cafefe",
                type: .login
            ),
        ]
        let expectedSearchResult = try [
            XCTUnwrap(
                VaultListItem(
                    cipherView: CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[1]))
                )
            ),
            XCTUnwrap(
                VaultListItem(
                    cipherView: CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[6]))
                )
            ),
        ]
        var iterator = try await subject
            .searchVaultListPublisher(
                searchText: "cafe",
                group: .login,
                filterType: .allVaults
            )
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchVaultListPublisher(searchText:, group: .secureNote, filterType:)`
    /// returns search matching cipher name for secure note items.
    func test_searchVaultListPublisher_searchText_secureNote() async throws {
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "café", type: .card),
            .fixture(id: "2", name: "cafepass", type: .login),
            .fixture(deletedDate: .now, id: "3", name: "deleted Café"),
            .fixture(
                folderId: "coffee",
                id: "0",
                name: "Best Cafes",
                type: .secureNote
            ),
            .fixture(
                collectionIds: ["123", "meep"],
                id: "4",
                name: "Café Friend",
                type: .identity
            ),
            .fixture(id: "5", name: "Café thoughts", type: .secureNote),
            .fixture(
                id: "6",
                login: .fixture(totp: .base32Key),
                name: "one time cafefe",
                type: .login
            ),
        ]
        let expectedSearchResult = try [
            XCTUnwrap(
                VaultListItem(
                    cipherView: CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[3]))
                )
            ),
            XCTUnwrap(
                VaultListItem(
                    cipherView: CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[5]))
                )
            ),
        ]
        var iterator = try await subject
            .searchVaultListPublisher(
                searchText: "cafe",
                group: .secureNote,
                filterType: .allVaults
            )
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchVaultListPublisher(searchText:, group: .totp, filterType:)`
    /// returns search matching cipher name for TOTP login items.
    func test_searchVaultListPublisher_searchText_totp() async throws {
        stateService.activeAccount = .fixture()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "café", type: .login),
            .fixture(id: "2", name: "cafepass", type: .login),
            .fixture(id: "5", name: "Café thoughts", type: .login),
            .fixture(
                id: "6",
                login: .fixture(totp: .base32Key),
                name: "one time cafefe",
                type: .login
            ),
        ]
        let totpCipher = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[3]))
        let expectedResults = try [
            VaultListItem(
                id: "6",
                itemType: .totp(
                    name: "one time cafefe",
                    totpModel: .init(
                        id: "6",
                        loginView: XCTUnwrap(totpCipher.login),
                        requiresMasterPassword: false,
                        totpCode: .init(
                            code: "123456",
                            codeGenerationDate: timeProvider.presentTime,
                            period: 30
                        )
                    )
                )
            ),
        ]

        var iterator = try await subject
            .searchVaultListPublisher(
                searchText: "cafe",
                group: .totp,
                filterType: .allVaults
            )
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedResults)
    }

    /// `searchVaultListPublisher(searchText:, filterType:)` returns search matching cipher id.
    func test_searchVaultListPublisher_searchText_id() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1223123", name: "dabcd"),
            .fixture(id: "31232131245435234", name: "qwe"),
            .fixture(id: "434343434", name: "Café"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value[1]))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchVaultListPublisher(searchText: "312321312", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchVaultListPublisher(searchText:, filterType:)` returns search matching cipher uri.
    func test_searchVaultListPublisher_searchText_uri() async throws {
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
                    uris: [.fixture(uri: "www.domain.com", match: .domain)],
                    totp: nil,
                    autofillOnPageLoad: nil,
                    fido2Credentials: nil
                ),
                name: "Café"
            ),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.last))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchVaultListPublisher(searchText: "domain", filterType: .allVaults)
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `searchVaultListPublisher(searchText:filterType:)` only returns ciphers based on search
    /// text and VaultFilterType.
    func test_searchVaultListPublisher_vaultType() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        cipherService.ciphersSubject.value = [
            .fixture(id: "1", name: "bcd", organizationId: "testOrg"),
            .fixture(id: "2", name: "bcdew"),
            .fixture(id: "3", name: "dabcd"),
        ]
        let cipherView = try CipherView(cipher: XCTUnwrap(cipherService.ciphersSubject.value.first))
        let expectedSearchResult = try [XCTUnwrap(VaultListItem(cipherView: cipherView))]
        var iterator = try await subject
            .searchVaultListPublisher(searchText: "bcd", filterType: .organization(.fixture(id: "testOrg")))
            .makeAsyncIterator()
        let ciphers = try await iterator.next()
        XCTAssertEqual(ciphers, expectedSearchResult)
    }

    /// `shareCipher()` has the cipher service share the cipher and updates the vault.
    func test_shareCipher() async throws {
        stateService.activeAccount = .fixtureAccountLogin()

        let cipher = CipherView.fixture()
        try await subject.shareCipher(cipher, newOrganizationId: "5", newCollectionIds: ["6", "7"])

        let updatedCipher = cipher.update(collectionIds: ["6", "7"])

        XCTAssertEqual(cipherService.shareCipherWithServerCiphers, [Cipher(cipherView: updatedCipher)])
        XCTAssertEqual(clientCiphers.encryptedCiphers.last, updatedCipher)
        XCTAssertEqual(clientCiphers.moveToOrganizationCipher, cipher)
        XCTAssertEqual(clientCiphers.moveToOrganizationOrganizationId, "5")

        XCTAssertEqual(cipherService.shareCipherWithServerCiphers.last, Cipher(cipherView: updatedCipher))
    }

    /// `shareCipher()` migrates any attachments without an attachment key.
    func test_shareCipher_attachmentMigration() async throws {
        let account = Account.fixtureAccountLogin()
        stateService.activeAccount = account

        // The original cipher.
        let cipherViewOriginal = CipherView.fixture(
            attachments: [
                .fixture(fileName: "file.txt", id: "1", key: nil),
                .fixture(fileName: "existing-attachment-key.txt", id: "2", key: "abc"),
            ],
            id: "1"
        )

        // The cipher after saving the new attachment, encrypted with an attachment key.
        let cipherAfterAttachmentSave = Cipher.fixture(
            attachments: [
                .fixture(id: "1", fileName: "file.txt", key: nil),
                .fixture(id: "2", fileName: "existing-attachment-key.txt", key: "abc"),
                .fixture(id: "3", fileName: "file.txt", key: "def"),
            ],
            id: "1"
        )
        cipherService.saveAttachmentWithServerResult = .success(cipherAfterAttachmentSave)

        // The cipher after deleting the old attachment without an attachment key.
        let cipherAfterAttachmentDelete = Cipher.fixture(
            attachments: [
                .fixture(id: "2", fileName: "existing-attachment-key.txt", key: "abc"),
                .fixture(id: "3", fileName: "file.txt", key: "def"),
            ],
            id: "1"
        )
        cipherService.deleteAttachmentWithServerResult = .success(cipherAfterAttachmentDelete)
        clientService.mockVault.clientCiphers.moveToOrganizationResult = .success(
            CipherView(cipher: cipherAfterAttachmentDelete)
        )

        // Temporary download file (would normally be created by the network layer).
        let downloadUrl = FileManager.default.temporaryDirectory.appendingPathComponent("file.txt")
        try Data("📁".utf8).write(to: downloadUrl)
        cipherService.downloadAttachmentResult = .success(downloadUrl)

        // Decrypted download file (would normally be created by the SDK when decrypting the attachment).
        let decryptUrl = try FileManager.default.attachmentsUrl(for: account.profile.userId)
            .appendingPathComponent("file.txt")
        try Data("🗂️".utf8).write(to: decryptUrl)

        try await subject.shareCipher(cipherViewOriginal, newOrganizationId: "5", newCollectionIds: ["6", "7"])

        let updatedCipherView = CipherView(cipher: cipherAfterAttachmentDelete).update(collectionIds: ["6", "7"])

        // Attachment migration: download attachment, save updated and delete old.
        XCTAssertEqual(cipherService.downloadAttachmentId, "1")
        XCTAssertEqual(cipherService.saveAttachmentWithServerCipher, Cipher(cipherView: cipherViewOriginal))
        XCTAssertEqual(cipherService.deleteAttachmentWithServerAttachmentId, "1")
        XCTAssertThrowsError(try Data(contentsOf: downloadUrl))
        XCTAssertThrowsError(try Data(contentsOf: decryptUrl))

        // Share cipher with updated attachments.
        XCTAssertEqual(cipherService.shareCipherWithServerCiphers, [Cipher(cipherView: updatedCipherView)])
        XCTAssertEqual(clientCiphers.encryptedCiphers.last, updatedCipherView)
        XCTAssertEqual(clientCiphers.moveToOrganizationCipher, CipherView(cipher: cipherAfterAttachmentDelete))
        XCTAssertEqual(clientCiphers.moveToOrganizationOrganizationId, "5")
    }

    /// `shouldShowUnassignedCiphersAlert` is true if the feature flag is on,
    /// we should check for this user, the user has organizations, and the user has unassigned ciphers.
    func test_shouldShowUnassignedCiphersAlert() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.unassignedItemsBanner] = true
        stateService.shouldCheckOrganizationUnassignedItems["1"] = true
        organizationService.fetchAllOrganizationsResult = .success([Organization.fixture()])
        cipherService.hasUnassignedCiphersResult = .success(true)
        let result = await subject.shouldShowUnassignedCiphersAlert()
        XCTAssertTrue(result)
    }

    /// `shouldShowUnassignedCiphersAlert` is false if user does not have any organizations.
    func test_shouldShowUnassignedCiphersAlert_noOrganizations() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.unassignedItemsBanner] = true
        stateService.shouldCheckOrganizationUnassignedItems["1"] = true
        organizationService.fetchAllOrganizationsResult = .success([])
        cipherService.hasUnassignedCiphersResult = .success(true)
        let result = await subject.shouldShowUnassignedCiphersAlert()
        XCTAssertFalse(result)
        XCTAssertFalse(cipherService.hasUnassignedCiphersCalled)
    }

    /// `shouldShowUnassignedCiphersAlert` is false if user does not have unassigned ciphers.
    func test_shouldShowUnassignedCiphersAlert_noUnassignedCiphers() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.unassignedItemsBanner] = true
        stateService.shouldCheckOrganizationUnassignedItems["1"] = true
        organizationService.fetchAllOrganizationsResult = .success([Organization.fixture()])
        cipherService.hasUnassignedCiphersResult = .success(false)
        let result = await subject.shouldShowUnassignedCiphersAlert()
        XCTAssertFalse(result)
        XCTAssertTrue(cipherService.hasUnassignedCiphersCalled)
    }

    /// `shouldShowUnassignedCiphersAlert` is false if the feature flag is off.
    /// And does not check for unassigned ciphers.
    func test_shouldShowUnassignedCiphersAlert_turnedOff() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.unassignedItemsBanner] = false
        stateService.shouldCheckOrganizationUnassignedItems["1"] = true
        organizationService.fetchAllOrganizationsResult = .success([Organization.fixture()])
        cipherService.hasUnassignedCiphersResult = .success(true)
        let result = await subject.shouldShowUnassignedCiphersAlert()
        XCTAssertFalse(result)
        XCTAssertFalse(cipherService.hasUnassignedCiphersCalled)
    }

    /// `shouldShowUnassignedCiphersAlert` is false if the user has seen and agreed to the alert before.
    /// And does not check for unassigned ciphers.
    func test_shouldShowUnassignedCiphersAlert_userAgreed() async {
        stateService.activeAccount = .fixture()
        configService.featureFlagsBool[.unassignedItemsBanner] = true
        stateService.shouldCheckOrganizationUnassignedItems["1"] = false
        organizationService.fetchAllOrganizationsResult = .success([Organization.fixture()])
        cipherService.hasUnassignedCiphersResult = .success(true)
        let result = await subject.shouldShowUnassignedCiphersAlert()
        XCTAssertFalse(result)
        XCTAssertFalse(cipherService.hasUnassignedCiphersCalled)
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
        vaultTimeoutService.isClientLocked = [account.profile.userId: false]
        await subject.remove(userId: account.profile.userId)
        XCTAssertTrue(vaultTimeoutService.removedIds.contains(account.profile.userId))
    }

    /// `remove(userId:)` Removes an account id from the vault timeout service.
    func test_removeAccountId_success_locked() async {
        let account = Account.fixtureAccountLogin()
        vaultTimeoutService.isClientLocked[account.profile.userId] = true
        await subject.remove(userId: account.profile.userId)
        XCTAssertTrue(vaultTimeoutService.removedIds.contains(account.profile.userId))
    }

    /// `remove(userId:)` Throws no error when no account is found.
    func test_removeAccountId_failure() async {
        let account = Account.fixtureAccountLogin()
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        await assertAsyncDoesNotThrow {
            await subject.remove(userId: "123")
        }
    }

    /// `repromptRequiredForCipher(id:)` returns `true` if reprompt is required for a cipher.
    func test_repromptRequiredForCipher() async throws {
        cipherService.fetchCipherResult = .success(.fixture(reprompt: .password))
        stateService.activeAccount = .fixture()
        let repromptRequired = try await subject.repromptRequiredForCipher(id: "1")
        XCTAssertTrue(repromptRequired)
    }

    /// `repromptRequiredForCipher(id:)` returns `false` if the cipher with the specified ID doesn't exist.
    func test_repromptRequiredForCipher_nilCipher() async throws {
        cipherService.fetchCipherResult = .success(nil)
        stateService.activeAccount = .fixture()

        let repromptRequired = try await subject.repromptRequiredForCipher(id: "1")
        XCTAssertFalse(repromptRequired)
    }

    /// `repromptRequiredForCipher(id:)` returns `false` if reprompt is required for a cipher but
    /// the user doesn't have a master password.
    func test_repromptRequiredForCipher_noMasterPassword() async throws {
        cipherService.fetchCipherResult = .success(.fixture(reprompt: .password))
        stateService.activeAccount = .fixture()
        stateService.userHasMasterPassword["1"] = false
        let repromptRequired = try await subject.repromptRequiredForCipher(id: "1")
        XCTAssertFalse(repromptRequired)
    }

    /// `repromptRequiredForCipher(id:)` returns `false` if reprompt isn't required for a cipher.
    func test_repromptRequiredForCipher_notRequired() async throws {
        cipherService.fetchCipherResult = .success(.fixture())
        stateService.activeAccount = .fixture()
        let repromptRequired = try await subject.repromptRequiredForCipher(id: "1")
        XCTAssertFalse(repromptRequired)
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

    /// `restoreCipher(_:cipher:)` updates the cipher on the server if the SDK adds a cipher key.
    func test_restoreCipher_updatesMigratedCipher() async throws {
        stateService.activeAccount = .fixture()
        let cipherView = CipherView.fixture(deletedDate: .now)
        let cipher = Cipher.fixture(key: "new key")
        clientCiphers.encryptCipherResult = .success(cipher)

        try await subject.restoreCipher(cipherView)

        XCTAssertEqual(cipherService.restoredCipher, cipher)
        XCTAssertEqual(cipherService.updateCipherWithServerCiphers, [cipher])
    }

    /// `saveAttachment(cipherView:fileData:fileName:)` saves the attachment to the cipher.
    func test_saveAttachment() async throws {
        cipherService.saveAttachmentWithServerResult = .success(.fixture(id: "42"))

        let cipherView = CipherView.fixture()
        let updatedCipher = try await subject.saveAttachment(
            cipherView: .fixture(),
            fileData: Data(),
            fileName: "Pineapple on pizza"
        )

        // Ensure all the steps completed as expected.
        XCTAssertEqual(clientService.mockVault.clientCiphers.encryptedCiphers, [.fixture()])
        XCTAssertEqual(clientService.mockVault.clientAttachments.encryptedBuffers, [Data()])
        XCTAssertEqual(cipherService.saveAttachmentWithServerCipher, Cipher(cipherView: cipherView))
        XCTAssertEqual(updatedCipher.id, "42")
    }

    /// `saveAttachment(cipherView:fileData:fileName:)` updates the cipher on the server if the SDK adds a cipher key.
    func test_saveAttachment_updatesMigratedCipher() async throws {
        cipherService.saveAttachmentWithServerResult = .success(.fixture(id: "42"))
        let cipher = Cipher.fixture(key: "new key")
        clientCiphers.encryptCipherResult = .success(cipher)

        let updatedCipher = try await subject.saveAttachment(
            cipherView: .fixture(),
            fileData: Data(),
            fileName: "Pineapple on pizza"
        )

        XCTAssertEqual(clientService.mockVault.clientCiphers.encryptedCiphers, [.fixture()])
        XCTAssertEqual(clientService.mockVault.clientAttachments.encryptedBuffers, [Data()])
        XCTAssertEqual(cipherService.updateCipherWithServerCiphers, [cipher])
        XCTAssertEqual(cipherService.saveAttachmentWithServerCipher, cipher)
        XCTAssertEqual(updatedCipher.id, "42")
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

    /// `softDeleteCipher(_:cipher:)` updates the cipher on the server if the SDK adds a cipher key.
    func test_softDeleteCipher_updatesMigratedCipher() async throws {
        stateService.activeAccount = .fixture()
        let cipherView = CipherView.fixture(deletedDate: .now)
        let cipher = Cipher.fixture(key: "new key")
        clientCiphers.encryptCipherResult = .success(cipher)

        try await subject.softDeleteCipher(cipherView)

        XCTAssertEqual(cipherService.softDeleteCipher, cipher)
        XCTAssertEqual(cipherService.updateCipherWithServerCiphers, [cipher])
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_card() async throws {
        let cipher = Cipher.fixture(id: "1", type: .card)
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .card, filter: .allVaults).makeAsyncIterator()
        let vaultListSections = try await iterator.next()

        XCTAssertEqual(
            vaultListSections,
            [
                VaultListSection(
                    id: "Items",
                    items: [.fixture(cipherView: .init(cipher: cipher))],
                    name: Localizations.items
                ),
            ]
        )
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_collection() async throws {
        let cipher = Cipher.fixture(collectionIds: ["1"], id: "1")
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(
            group: .collection(id: "1", name: "", organizationId: "1"),
            filter: .allVaults
        )
        .makeAsyncIterator()
        let vaultListSections = try await iterator.next()

        XCTAssertEqual(
            vaultListSections,
            [
                VaultListSection(
                    id: "Items",
                    items: [.fixture(cipherView: .init(cipher: cipher))],
                    name: Localizations.items
                ),
            ]
        )
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list sections within
    /// the collection group with nested collections.
    func test_vaultListPublisher_groups_collection_nestedCollections() async throws {
        let workCipher = Cipher.fixture(collectionIds: ["1"], id: "1")
        let workEngineeringCipher = Cipher.fixture(collectionIds: ["3"], id: "2")
        cipherService.ciphersSubject.send([workCipher, workEngineeringCipher])

        let workCollection = Collection.fixture(id: "1", name: "Work")
        let workDesignCollection = Collection.fixture(id: "2", name: "Work/Design")
        let workEngineeringCollection = Collection.fixture(id: "3", name: "Work/Engineering")
        collectionService.collectionsSubject.send([workCollection, workDesignCollection, workEngineeringCollection])

        var iterator = try await subject.vaultListPublisher(
            group: .collection(id: "1", name: "", organizationId: "1"),
            filter: .allVaults
        ).makeAsyncIterator()
        let vaultListSections = try await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(vaultListSections)), as: .lines) {
            """
            Section: Collections
              - Group: Design (0)
              - Group: Engineering (1)
            Section: Items
              - Cipher: Bitwarden
            """
        }
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_folder() async throws {
        let cipher = Cipher.fixture(folderId: "1", id: "1")
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .folder(id: "1", name: ""), filter: .allVaults)
            .makeAsyncIterator()
        let vaultListSections = try await iterator.next()

        XCTAssertEqual(
            vaultListSections,
            [
                VaultListSection(
                    id: "Items",
                    items: [.fixture(cipherView: .init(cipher: cipher))],
                    name: Localizations.items
                ),
            ]
        )
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list sections within
    /// the folder group with nested folders.
    func test_vaultListPublisher_groups_folder_nestedFolders() async throws {
        let workCipher = Cipher.fixture(folderId: "1", id: "1")
        let workEngineeringCipher = Cipher.fixture(folderId: "3", id: "2")
        cipherService.ciphersSubject.send([workCipher, workEngineeringCipher])

        let workFolder = Folder.fixture(id: "1", name: "Work")
        let workDesignFolder = Folder.fixture(id: "2", name: "Work/Design")
        let workEngineeringFolder = Folder.fixture(id: "3", name: "Work/Engineering")
        folderService.foldersSubject.send([workFolder, workDesignFolder, workEngineeringFolder])

        var iterator = try await subject.vaultListPublisher(group: .folder(id: "1", name: ""), filter: .allVaults)
            .makeAsyncIterator()
        let vaultListSections = try await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(vaultListSections)), as: .lines) {
            """
            Section: Folder
              - Group: Design (0)
              - Group: Engineering (1)
            Section: Items
              - Cipher: Bitwarden
            """
        }
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_identity() async throws {
        let cipher = Cipher.fixture(id: "1", type: .identity)
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .identity, filter: .allVaults).makeAsyncIterator()
        let vaultListSections = try await iterator.next()

        XCTAssertEqual(
            vaultListSections,
            [
                VaultListSection(
                    id: "Items",
                    items: [.fixture(cipherView: .init(cipher: cipher))],
                    name: Localizations.items
                ),
            ]
        )
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_login() async throws {
        let cipher = Cipher.fixture(id: "1", type: .login)
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .login, filter: .allVaults).makeAsyncIterator()
        let vaultListSections = try await iterator.next()

        XCTAssertEqual(
            vaultListSections,
            [
                VaultListSection(
                    id: "Items",
                    items: [.fixture(cipherView: .init(cipher: cipher))],
                    name: Localizations.items
                ),
            ]
        )
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_secureNote() async throws {
        let cipher = Cipher.fixture(id: "1", type: .secureNote)
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .secureNote, filter: .allVaults).makeAsyncIterator()
        let vaultListSections = try await iterator.next()

        XCTAssertEqual(
            vaultListSections,
            [
                VaultListSection(
                    id: "Items",
                    items: [.fixture(cipherView: .init(cipher: cipher))],
                    name: Localizations.items
                ),
            ]
        )
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items for premium accounts.
    func test_vaultListPublisher_groups_totp_premium() async throws {
        stateService.activeAccount = premiumAccount
        let cipher = Cipher.fixture(id: "1", login: .fixture(totp: "123"), type: .login)
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .totp, filter: .allVaults).makeAsyncIterator()
        let vaultListSections = try await iterator.next()
        let vaultListItems = try XCTUnwrap(vaultListSections).flatMap(\.items)

        let itemType = try XCTUnwrap(vaultListItems.last?.itemType)
        if case let .totp(name, _) = itemType {
            XCTAssertEqual(name, "Bitwarden")
        } else {
            XCTFail("Totp item not found")
        }
    }

    /// `vaultListPublisher(group:filter:)` does not return TOTP items for non-premium accounts.
    func test_vaultListPublisher_groups_totp_notPremium() async throws {
        stateService.activeAccount = nonPremiumAccount
        stateService.doesActiveAccountHavePremiumResult = .success(false)
        let cipher = Cipher.fixture(id: "1", login: .fixture(totp: "123"), type: .login)
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .totp, filter: .allVaults).makeAsyncIterator()
        let vaultListSections = try await iterator.next()
        let vaultListItems = try XCTUnwrap(vaultListSections).flatMap(\.items)
        XCTAssertTrue(vaultListItems.isEmpty)
    }

    /// `vaultListPublisher(group:filter:)` filters out TOTP items with keys that
    ///      the SDK cannot parse into TOTP codes.
    func test_vaultListPublisher_groups_totp_invalidCode() async throws {
        stateService.activeAccount = premiumAccount
        let cipher = Cipher.fixture(id: "1", login: .fixture(totp: "123"), type: .login)
        struct InvalidCodeError: Error, Equatable {}
        clientService.mockVault.generateTOTPCodeResult = .failure(InvalidCodeError())
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .totp, filter: .allVaults).makeAsyncIterator()
        let vaultListSections = try await iterator.next()

        try XCTAssertTrue(XCTUnwrap(vaultListSections).allSatisfy(\.items.isEmpty))
    }

    /// `vaultListPublisher(group:filter:)` returns a publisher for the vault list items.
    func test_vaultListPublisher_groups_trash() async throws {
        let cipher = Cipher.fixture(deletedDate: Date(), id: "1")
        cipherService.ciphersSubject.send([cipher])

        var iterator = try await subject.vaultListPublisher(group: .trash, filter: .allVaults).makeAsyncIterator()
        let vaultListSections = try await iterator.next()

        XCTAssertEqual(
            vaultListSections,
            [
                VaultListSection(
                    id: "Items",
                    items: [.fixture(cipherView: .init(cipher: cipher))],
                    name: Localizations.items
                ),
            ]
        )
    }

    /// `vaultListPublisher(filter:)` returns a publisher for the vault list sections.
    func test_vaultListPublisher_section_premium() async throws { // swiftlint:disable:this function_body_length
        stateService.activeAccount = premiumAccount
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
                items: [
                    .fixtureGroup(id: "1", group: .folder(id: "1", name: ""), count: 1),
                    .init(id: "NoFolderFolderItem", itemType: .group(.noFolder, 2)),
                ],
                name: Localizations.folders
            ),
            .init(
                id: "Collections",
                items: [
                    .fixtureGroup(
                        id: "1",
                        group: .collection(id: "1", name: "", organizationId: ""),
                        count: 1
                    ),
                ],
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

    /// `vaultListPublisher(filter:)` returns a publisher for the vault list sections
    ///   with no TOTP items for accounts without premium.
    func test_vaultListPublisher_section_nonPremium() async throws { // swiftlint:disable:this function_body_length
        stateService.activeAccount = nonPremiumAccount
        stateService.doesActiveAccountHavePremiumResult = .success(false)
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
                items: [
                    .fixtureGroup(id: "1", group: .folder(id: "1", name: ""), count: 1),
                    .init(id: "NoFolderFolderItem", itemType: .group(.noFolder, 2)),
                ],
                name: Localizations.folders
            ),
            .init(
                id: "Collections",
                items: [
                    .fixtureGroup(
                        id: "1",
                        group: .collection(id: "1", name: "", organizationId: ""),
                        count: 1
                    ),
                ],
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
        stateService.activeAccount = .fixture()
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
        stateService.activeAccount = .fixture()
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

    /// `vaultListPublisher(filter:)`should return `NoFolder` items as folder item, when collections are available.
    func test_vaultListPublisher_section_noFolderItem() async throws { // swiftlint:disable:this function_body_length
        stateService.activeAccount = .fixture()
        let ciphers: [Cipher] = [
            .fixture(folderId: "1", id: "1", type: .login),
            .fixture(id: "2", login: .fixture(), type: .login),
            .fixture(collectionIds: ["1"], favorite: false, id: "3"),
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
                items: [
                    .fixtureGroup(id: "1", group: .folder(id: "1", name: ""), count: 1),
                    .init(id: "NoFolderFolderItem", itemType: .group(.noFolder, 2)),
                ],
                name: Localizations.folders
            ),
            .init(
                id: "Collections",
                items: [
                    .fixtureGroup(
                        id: "1",
                        group: .collection(id: "1", name: "", organizationId: ""),
                        count: 1
                    ),
                ],
                name: Localizations.collections
            ),
            .init(
                id: "Trash",
                items: [.fixtureGroup(id: "Trash", group: .trash, count: 1)],
                name: Localizations.trash
            ),
        ]
        XCTAssertEqual(
            vaultListSections,
            expectedResult
        )
    }

    /// `vaultListPublisher(filter:)`should return `NoFolder` items as folder item, when there are
    /// more than 100 ciphers without a folder assigned.
    func test_vaultListPublisher_section_100Cipher() async throws {
        stateService.activeAccount = .fixture()
        var ciphers: [Cipher] = []
        for index in 1 ... 100 {
            ciphers.append(.fixture(id: "\(index)", type: .login))
        }
        let folder = Folder.fixture(id: "1")
        cipherService.ciphersSubject.send(ciphers)
        folderService.foldersSubject.send([folder])

        var iterator = try await subject.vaultListPublisher(filter: .allVaults).makeAsyncIterator()
        let vaultListSections = try await iterator.next()
        let expectedResult: [VaultListSection] = [
            .init(
                id: "Types",
                items: [
                    .fixtureGroup(id: "Types.Logins", group: .login, count: 100),
                    .fixtureGroup(id: "Types.Cards", group: .card, count: 0),
                    .fixtureGroup(id: "Types.Identities", group: .identity, count: 0),
                    .fixtureGroup(id: "Types.SecureNotes", group: .secureNote, count: 0),
                ],
                name: Localizations.types
            ),
            .init(
                id: "Folders",
                items: [
                    .fixtureGroup(id: "1", group: .folder(id: "1", name: ""), count: 0),
                    .init(id: "NoFolderFolderItem", itemType: .group(.noFolder, 100)),
                ],
                name: Localizations.folders
            ),
            .init(
                id: "Trash",
                items: [.fixtureGroup(id: "Trash", group: .trash, count: 0)],
                name: Localizations.trash
            ),
        ]
        XCTAssertEqual(
            vaultListSections,
            expectedResult
        )
    }

    /// `vaultListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the vault for a vault that contains collections and folders, with no filter.
    func test_vaultListPublisher_withCollections_all() async throws {
        stateService.activeAccount = .fixture()
        let syncResponse = try JSONDecoder.defaultDecoder.decode(
            SyncResponseModel.self,
            from: APITestData.syncWithCiphersCollections.data
        )
        cipherService.ciphersSubject.send(syncResponse.ciphers.compactMap(Cipher.init))
        collectionService.collectionsSubject.send(syncResponse.collections.compactMap(Collection.init))
        folderService.foldersSubject.send(syncResponse.folders.compactMap(Folder.init))

        var iterator = try await subject.vaultListPublisher(filter: .allVaults).makeAsyncIterator()
        let sections = try await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(sections)), as: .lines) {
            """
            Section: Favorites
              - Cipher: Apple
            Section: Types
              - Group: Login (6)
              - Group: Card (1)
              - Group: Identity (1)
              - Group: Secure note (1)
            Section: Folders
              - Group: Development (0)
              - Group: Internal (1)
              - Group: Social (2)
              - Group: No Folder (5)
            Section: Collections
              - Group: Design (2)
              - Group: Engineering (3)
            Section: Trash
              - Group: Trash (1)
            """
        }
    }

    /// `vaultListPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the vault for a vault that contains collections with the my vault filter.
    func test_vaultListPublisher_withCollections_myVault() async throws {
        stateService.activeAccount = .fixture()
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
        stateService.activeAccount = .fixture()
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
              - Group: Login (5)
              - Group: Card (0)
              - Group: Identity (0)
              - Group: Secure note (0)
            Section: Folders
              - Group: Development/Artifacts (1)
              - Group: Internal (1)
              - Group: Social (1)
              - Group: No Folder (2)
            Section: Collections
              - Group: Design (2)
              - Group: Engineering (3)
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

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(items)), as: .lines) {
            """
            Section: Items
              - Cipher: Apple
              - Cipher: Azure
              - Cipher: Facebook
              - Cipher: Figma
              - Cipher: Reddit
              - Cipher: Zoom
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

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(items)), as: .lines) {
            """
            Section: Items
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

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(items)), as: .lines) {
            """
            Section: Items
              - Cipher: Apple
              - Cipher: Azure
              - Cipher: Figma
              - Cipher: Reddit
              - Cipher: Zoom
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
            group: .collection(
                id: "f96de98e-618a-4886-b396-66b92a385325",
                name: "Engineering",
                organizationId: "ba756e34-4650-4e8a-8cbb-6e98bfae9abf"
            ),
            filter: .allVaults
        ).makeAsyncIterator()
        let items = try await iterator.next()

        try assertInlineSnapshot(of: dumpVaultListSections(XCTUnwrap(items)), as: .lines) {
            """
            Section: Items
              - Cipher: Apple
              - Cipher: Azure
              - Cipher: Reddit
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
