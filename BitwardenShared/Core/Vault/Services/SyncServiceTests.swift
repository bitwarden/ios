import XCTest

@testable import BitwardenShared

import BitwardenSdk

class SyncServiceTests: BitwardenTestCase {
    // MARK: Properties

    var cipherService: MockCipherService!
    var client: MockHTTPClient!
    var clientVault: MockClientVaultService!
    var collectionService: MockCollectionService!
    var folderService: MockFolderService!
    var organizationService: MockOrganizationService!
    var policyService: MockPolicyService!
    var sendService: MockSendService!
    var settingsService: MockSettingsService!
    var stateService: MockStateService!
    var subject: SyncService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        client = MockHTTPClient()
        clientVault = MockClientVaultService()
        collectionService = MockCollectionService()
        folderService = MockFolderService()
        organizationService = MockOrganizationService()
        policyService = MockPolicyService()
        sendService = MockSendService()
        settingsService = MockSettingsService()
        stateService = MockStateService()

        subject = DefaultSyncService(
            cipherService: cipherService,
            clientVault: clientVault,
            collectionService: collectionService,
            folderService: folderService,
            organizationService: organizationService,
            policyService: policyService,
            sendService: sendService,
            settingsService: settingsService,
            stateService: stateService,
            syncAPIService: APIService(client: client)
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        client = nil
        clientVault = nil
        collectionService = nil
        folderService = nil
        organizationService = nil
        policyService = nil
        sendService = nil
        settingsService = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `fetchSync()` performs the sync API request.
    func test_fetchSync() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].method, .get)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/sync")

        try XCTAssertEqual(
            XCTUnwrap(stateService.lastSyncTimeByUserId["1"]).timeIntervalSince1970,
            Date().timeIntervalSince1970,
            accuracy: 1
        )
    }

    /// `fetchSync()` replaces the list of the user's ciphers.
    func test_fetchSync_ciphers() async throws {
        client.result = .httpSuccess(testData: .syncWithCipher)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        let date = Date(year: 2023, month: 8, day: 10, hour: 8, minute: 33, second: 45, nanosecond: 345_000_000)
        XCTAssertEqual(
            cipherService.replaceCiphersCiphers,
            [
                CipherDetailsResponseModel.fixture(
                    creationDate: date,
                    edit: true,
                    id: "3792af7a-4441-11ee-be56-0242ac120002",
                    login: .fixture(
                        password: "encrypted password",
                        totp: "totp",
                        uris: [
                            CipherLoginUriModel(match: nil, uri: "encrypted uri"),
                        ],
                        username: "encrypted username"
                    ),
                    name: "encrypted name",
                    revisionDate: date,
                    type: .login,
                    viewPassword: true
                ),
            ]
        )
        XCTAssertEqual(cipherService.replaceCiphersUserId, "1")
    }

    /// `fetchSync()` replaces the list of the user's collections.
    func test_fetchSync_collections() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphersCollections)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertEqual(
            collectionService.replaceCollectionsCollections,
            [
                CollectionDetailsResponseModel.fixture(
                    id: "f96de98e-618a-4886-b396-66b92a385325",
                    name: "Engineering",
                    organizationId: "ba756e34-4650-4e8a-8cbb-6e98bfae9abf"
                ),
                CollectionDetailsResponseModel.fixture(
                    id: "a468e453-7141-49cf-bb15-58448c2b27b9",
                    name: "Design",
                    organizationId: "ba756e34-4650-4e8a-8cbb-6e98bfae9abf"
                ),
            ]
        )
        XCTAssertEqual(collectionService.replaceCollectionsUserId, "1")
    }

    /// `fetchSync()` updates the user's profile.
    func test_fetchSync_profile() async throws {
        client.result = .httpSuccess(testData: .syncWithProfile)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertEqual(
            stateService.updateProfileResponse,
            .fixture(
                culture: "en-US",
                email: "user@bitwarden.com",
                id: "c8aa1e36-4427-11ee-be56-0242ac120002",
                key: "key",
                organizations: [],
                privateKey: "private key",
                securityStamp: "security stamp"
            )
        )
        XCTAssertEqual(stateService.updateProfileUserId, "1")
    }

    /// `fetchSync()` replaces the list of the user's sends.
    func test_fetchSync_sends() async throws {
        client.result = .httpSuccess(testData: .syncWithSends)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertEqual(
            sendService.replaceSendsSends,
            [
                SendResponseModel.fixture(
                    accessId: "access id",
                    deletionDate: Date(timeIntervalSince1970: 1_691_443_980),
                    id: "fc483c22-443c-11ee-be56-0242ac120002",
                    key: "encrypted key",
                    name: "encrypted name",
                    revisionDate: Date(timeIntervalSince1970: 1_690_925_611.636),
                    text: SendTextModel(
                        hidden: false,
                        text: "encrypted text"
                    ),
                    type: .text
                ),
                SendResponseModel.fixture(
                    accessId: "access id",
                    deletionDate: Date(timeIntervalSince1970: 1_692_230_400),
                    file: SendFileModel(
                        fileName: "test.txt",
                        id: "1",
                        size: "123",
                        sizeName: "123 KB"
                    ),
                    id: "d7a7e48c-443f-11ee-be56-0242ac120002",
                    key: "encrypted key",
                    name: "encrypted name",
                    revisionDate: Date(timeIntervalSince1970: 1_691_625_600),
                    type: .file
                ),
            ]
        )
        XCTAssertEqual(sendService.replaceSendsUserId, "1")
    }

    /// `fetchSync()` replaces the list of the user's equivalent domains.
    func test_fetchSync_domains() async throws {
        client.result = .httpSuccess(testData: .syncWithDomains)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertEqual(
            settingsService.replaceEquivalentDomainsDomains,
            DomainsResponseModel(
                equivalentDomains: [["example.com", "test.com"]],
                globalEquivalentDomains: [
                    GlobalDomains(domains: ["apple.com", "icloud.com"], excluded: false, type: 1),
                ]
            )
        )
    }

    /// `fetchSync()` replaces the list of the user's folders.
    func test_fetchSync_folders() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertEqual(
            folderService.replaceFoldersFolders,
            [
                FolderResponseModel(
                    id: "3270afb7-e3d7-495a-8867-c66cf272f795",
                    name: "Social",
                    revisionDate: Date(year: 2023, month: 10, day: 9, hour: 3, minute: 44, second: 59)
                ),
            ]
        )
        XCTAssertEqual(folderService.replaceFoldersUserId, "1")
    }

    /// `fetchSync()` replaces the list of the user's organizations.
    func test_fetchSync_organizations() async throws {
        client.result = .httpSuccess(testData: .syncWithProfileOrganizations)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertTrue(organizationService.initializeOrganizationCryptoWithOrgsCalled)
        XCTAssertEqual(organizationService.replaceOrganizationsOrganizations?.count, 2)
        XCTAssertEqual(organizationService.replaceOrganizationsOrganizations?[0].id, "ORG_1")
        XCTAssertEqual(organizationService.replaceOrganizationsOrganizations?[1].id, "ORG_2")
        XCTAssertEqual(organizationService.replaceOrganizationsUserId, "1")
    }

    /// `fetchSync()` replaces the list of the user's policies.
    func test_fetchSync_polices() async throws {
        client.result = .httpSuccess(testData: .syncWithPolicies)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync()

        XCTAssertEqual(policyService.replacePoliciesPolicies.count, 4)
        XCTAssertEqual(
            policyService.replacePoliciesPolicies[0],
            .fixture(enabled: false, id: "policy-0", organizationId: "org-1", type: .twoFactorAuthentication)
        )
        XCTAssertEqual(
            policyService.replacePoliciesPolicies[1],
            .fixture(
                data: [
                    "minComplexity": .null,
                    "minLength": .int(12),
                    "requireUpper": .bool(true),
                    "requireLower": .bool(true),
                    "requireNumbers": .bool(true),
                    "requireSpecial": .bool(false),
                    "enforceOnLogin": .bool(false),
                ],
                enabled: true,
                id: "policy-1",
                organizationId: "org-1",
                type: .masterPassword
            )
        )
        XCTAssertEqual(
            policyService.replacePoliciesPolicies[2],
            .fixture(enabled: false, id: "policy-3", organizationId: "org-1", type: .onlyOrg)
        )
        XCTAssertEqual(
            policyService.replacePoliciesPolicies[3],
            .fixture(
                data: ["autoEnrollEnabled": .bool(false)],
                enabled: true,
                id: "policy-8",
                organizationId: "org-1",
                type: .resetPassword
            )
        )
        XCTAssertEqual(policyService.replacePoliciesUserId, "1")
    }

    /// `fetchSync()` throws an error if the request fails.
    func test_fetchSync_error() async throws {
        client.result = .httpFailure()
        stateService.activeAccount = .fixture()

        await assertAsyncThrows {
            try await subject.fetchSync()
        }
    }

    func test_deleteCipher() async throws {
        stateService.activeAccount = .fixture()
        cipherService.deleteCipherWithLocalStorageResult = .success(())

        let notification = SyncCipherNotification(
            collectionIds: nil,
            id: "id",
            organizationId: nil,
            revisionDate: nil,
            userId: "1"
        )
        try await subject.deleteCipher(data: notification)
        XCTAssertEqual(cipherService.deleteCipherWithLocalStorageId, "id")
    }

    func test_deleteFolder() async throws {
        stateService.activeAccount = .fixture()
        folderService.deleteFolderWithLocalStorageResult = .success(())
        cipherService.fetchAllCiphersResult = .success([.fixture(folderId: "id")])
        cipherService.updateCipherWithLocalStorageResult = .success(())

        let notification = SyncFolderNotification(
            id: "id",
            revisionDate: nil,
            userId: "1"
        )
        try await subject.deleteFolder(data: notification)
        XCTAssertEqual(folderService.deleteFolderWithLocalStorageId, "id")
        XCTAssertEqual(cipherService.updateCipherWithLocalStorageCipher, .fixture(folderId: nil))
    }

    func test_deleteSend() async throws {
        stateService.activeAccount = .fixture()
        sendService.deleteSendWithLocalStorageResult = .success(())

        let notification = SyncSendNotification(
            id: "id",
            revisionDate: nil,
            userId: "1"
        )
        try await subject.deleteSend(data: notification)
        XCTAssertEqual(sendService.deleteSendWithLocalStorageId, "id")
    }

    func test_fetchUpsertSyncCipher() async throws {
        stateService.activeAccount = .fixture()
        cipherService.syncCipherWithServerResult = .success(())

        let notification = SyncCipherNotification(
            collectionIds: nil,
            id: "id",
            organizationId: nil,
            revisionDate: nil,
            userId: "1"
        )
        try await subject.fetchUpsertSyncCipher(data: notification)
        XCTAssertEqual(cipherService.syncCipherWithServerId, "id")
    }

    func test_fetchUpsertSyncFolder() async throws {
        stateService.activeAccount = .fixture()
        folderService.syncFolderWithServerResult = .success(())

        let notification = SyncFolderNotification(
            id: "id",
            revisionDate: nil,
            userId: "1"
        )
        try await subject.fetchUpsertSyncFolder(data: notification)
        XCTAssertEqual(folderService.syncFolderWithServerId, "id")
    }

    func test_fetchUpsertSyncSend() async throws {
        stateService.activeAccount = .fixture()
        sendService.syncSendWithServerResult = .success(())

        let notification = SyncSendNotification(
            id: "id",
            revisionDate: nil,
            userId: "1"
        )
        try await subject.fetchUpsertSyncSend(data: notification)
        XCTAssertEqual(sendService.syncSendWithServerId, "id")
    }
} // swiftlint:disable:this file_length
