import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared

import BitwardenSdk

// swiftlint:disable:next type_body_length
class SyncServiceTests: BitwardenTestCase {
    // MARK: Properties

    var cipherService: MockCipherService!
    var client: MockHTTPClient!
    var clientService: MockClientService!
    var collectionService: MockCollectionService!
    var folderService: MockFolderService!
    var keyConnectorService: MockKeyConnectorService!
    var organizationService: MockOrganizationService!
    var policyService: MockPolicyService!
    var sendService: MockSendService!
    var settingsService: MockSettingsService!
    var stateService: MockStateService!
    var subject: SyncService!
    var syncServiceDelegate: MockSyncServiceDelegate!
    var timeProvider: MockTimeProvider!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        client = MockHTTPClient()
        clientService = MockClientService()
        collectionService = MockCollectionService()
        folderService = MockFolderService()
        keyConnectorService = MockKeyConnectorService()
        organizationService = MockOrganizationService()
        policyService = MockPolicyService()
        sendService = MockSendService()
        settingsService = MockSettingsService()
        stateService = MockStateService()
        syncServiceDelegate = MockSyncServiceDelegate()
        timeProvider = MockTimeProvider(
            .mockTime(
                Date(
                    year: 2024,
                    month: 2,
                    day: 14
                )
            )
        )
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultSyncService(
            accountAPIService: APIService(client: client),
            cipherService: cipherService,
            clientService: clientService,
            collectionService: collectionService,
            folderService: folderService,
            keyConnectorService: keyConnectorService,
            organizationService: organizationService,
            policyService: policyService,
            sendService: sendService,
            settingsService: settingsService,
            stateService: stateService,
            syncAPIService: APIService(client: client),
            timeProvider: timeProvider,
            vaultTimeoutService: vaultTimeoutService
        )
        subject.delegate = syncServiceDelegate
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        client = nil
        clientService = nil
        collectionService = nil
        folderService = nil
        keyConnectorService = nil
        organizationService = nil
        policyService = nil
        sendService = nil
        settingsService = nil
        stateService = nil
        subject = nil
        syncServiceDelegate = nil
        timeProvider = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `checkTdeUserNeedsToSetPassword()` on sync check if the user needs to set a password
    ///
    func test_checkTdeUserNeedsToSetPassword_true() async throws {
        client.result = .httpSuccess(testData: .syncWithProfileSingleOrg)
        stateService.activeAccount = .fixtureWithTdeNoPassword()

        try await subject.fetchSync(forceSync: false)

        XCTAssertTrue(syncServiceDelegate.setMasterPasswordCalled)
        XCTAssertEqual(syncServiceDelegate.setMasterPasswordOrgId, "org-2")
    }

    /// `checkTdeUserNeedsToSetPassword()` on sync check if the user needs to set a password
    ///
    func test_checkTdeUserNeedsToSetPassword_false() async throws {
        client.result = .httpSuccess(testData: .syncWithProfileSingleOrg)
        stateService.activeAccount = .fixtureWithTDE()

        try await subject.fetchSync(forceSync: false)

        XCTAssertFalse(syncServiceDelegate.setMasterPasswordCalled)
        XCTAssertNil(syncServiceDelegate.setMasterPasswordOrgId)
    }

    /// `checkTdeUserNeedsToSetPassword()` returns false if the user doesn't use TDE.
    func test_checkTdeUserNeedsToSetPassword_false_nonTDE() async throws {
        client.result = .httpSuccess(testData: .syncWithProfileSingleOrg)
        stateService.activeAccount = .fixture(
            profile: .fixture(
                userDecryptionOptions: UserDecryptionOptions(
                    hasMasterPassword: false,
                    keyConnectorOption: KeyConnectorUserDecryptionOption(keyConnectorUrl: ""),
                    trustedDeviceOption: nil
                )
            )
        )

        try await subject.fetchSync(forceSync: false)
        XCTAssertFalse(syncServiceDelegate.setMasterPasswordCalled)
    }

    /// `fetchSync()` only updates the user's timeout action to match the policy's
    /// if the user's timeout value is less than the policy's.
    func test_checkVaultTimeoutPolicy_actionOnly() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)
        stateService.activeAccount = .fixture()
        policyService.fetchTimeoutPolicyValuesResult = .success((.logout, 60))

        try await subject.fetchSync(forceSync: false)

        XCTAssertEqual(stateService.timeoutAction["1"], .logout)
        XCTAssertNil(stateService.vaultTimeout["1"])
    }

    /// `fetchSync()` updates the user's timeout action and value
    /// if the user's timeout value is greater than the policy's.
    func test_checkVaultTimeoutPolicy_actionAndValue() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)
        stateService.activeAccount = .fixture()
        stateService.vaultTimeout["1"] = SessionTimeoutValue(rawValue: 120)

        policyService.fetchTimeoutPolicyValuesResult = .success((.logout, 60))

        try await subject.fetchSync(forceSync: false)

        XCTAssertEqual(stateService.timeoutAction["1"], .logout)
        XCTAssertEqual(stateService.vaultTimeout["1"], SessionTimeoutValue(rawValue: 60))
    }

    /// `fetchSync()` updates the user's timeout action and value - if the timeout value is set to
    /// never, it is set to the maximum timeout allowed by the policy.
    func test_checkVaultTimeoutPolicy_valueNever() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)
        stateService.activeAccount = .fixture()
        stateService.vaultTimeout["1"] = .never

        policyService.fetchTimeoutPolicyValuesResult = .success((.lock, 15))

        try await subject.fetchSync(forceSync: false)

        XCTAssertEqual(stateService.timeoutAction["1"], .lock)
        XCTAssertEqual(stateService.vaultTimeout["1"], SessionTimeoutValue.fifteenMinutes)
    }

    /// `fetchSync()` performs the sync API request.
    func test_fetchSync() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync(forceSync: false)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].method, .get)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/sync")
        XCTAssertEqual(syncServiceDelegate.onFetchSyncSucceededCalledWithuserId, "1")

        try XCTAssertEqual(
            XCTUnwrap(stateService.lastSyncTimeByUserId["1"]),
            timeProvider.presentTime
        )
    }

    /// `fetchSync()` with `forceSync: true` performs the sync API request regardless of the
    /// account revision or sync interval.
    func test_fetchSync_failedParse() async throws {
        client.results = [
            .httpSuccess(testData: .accountRevisionDate(timeProvider.presentTime)),
            .httpSuccess(testData: .syncWithCipher),
        ]
        stateService.activeAccount = .fixture()
        let priorSyncDate = Date(year: 2022, month: 1, day: 1)
        stateService.lastSyncTimeByUserId["1"] = priorSyncDate
        cipherService.replaceCiphersError = BitwardenTestError.example
        keyConnectorService.userNeedsMigrationResult = .success(false)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.fetchSync(forceSync: false)
        }

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertNotNil(cipherService.replaceCiphersCiphers)

        try XCTAssertEqual(
            XCTUnwrap(stateService.lastSyncTimeByUserId["1"]),
            priorSyncDate
        )
    }

    /// `fetchSync()` with `forceSync: true` performs the sync API request regardless of the
    /// account revision or sync interval.
    func test_fetchSync_forceSync() async throws {
        client.result = .httpSuccess(testData: .syncWithCiphers)
        stateService.activeAccount = .fixture()
        stateService.lastSyncTimeByUserId["1"] = timeProvider.presentTime

        try await subject.fetchSync(forceSync: true)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].method, .get)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/sync")

        try XCTAssertEqual(
            XCTUnwrap(stateService.lastSyncTimeByUserId["1"]),
            timeProvider.presentTime
        )
    }

    /// `fetchSync()` syncs if the last sync time is greater than 30 minutes ago, is periodic and the account has
    /// newer revisions.
    func test_fetchSync_needsSync_lastSyncTime_older30MinsWithRevisions() async throws {
        client.results = [
            .httpSuccess(testData: .accountRevisionDate(timeProvider.presentTime)),
            .httpSuccess(testData: .syncWithCipher),
        ]
        stateService.activeAccount = .fixture()
        let lastSync = timeProvider.presentTime.addingTimeInterval(-(Constants.minimumSyncInterval + 1))
        stateService.lastSyncTimeByUserId["1"] = try XCTUnwrap(
            lastSync
        )
        keyConnectorService.userNeedsMigrationResult = .success(false)

        try await subject.fetchSync(forceSync: false, isPeriodic: true)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertNotNil(cipherService.replaceCiphersCiphers)

        try XCTAssertEqual(
            XCTUnwrap(stateService.lastSyncTimeByUserId["1"]),
            timeProvider.presentTime
        )
    }

    /// `fetchSync()` doesn't sync if the last sync time is greater than 30 minutes, is periodic but fetching
    /// the account revision date fails.
    func test_fetchSync_needsSync_lastSyncTime_older30Mins_revisionsError() async throws {
        let lastSyncTime = try XCTUnwrap(
            timeProvider.presentTime.addingTimeInterval(-(Constants.minimumSyncInterval + 1))
        )
        client.result = .httpFailure(BitwardenTestError.example)
        stateService.activeAccount = .fixture()
        stateService.lastSyncTimeByUserId["1"] = lastSyncTime
        keyConnectorService.userNeedsMigrationResult = .success(false)

        try await subject.fetchSync(forceSync: false, isPeriodic: true)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(cipherService.replaceCiphersCiphers)

        XCTAssertEqual(stateService.lastSyncTimeByUserId["1"], lastSyncTime)
    }

    /// `fetchSync()` doesn't syncs if the last sync time is greater than 30 minutes ago, is periodic but the
    /// account doesn't have newer revisions.
    func test_fetchSync_needsSync_lastSyncTime_older30MinsWithoutRevisions() async throws {
        let lastRevision = try XCTUnwrap(timeProvider.presentTime.addingTimeInterval(-24 * 60 * 60))
        client.results = [
            .httpSuccess(testData: .accountRevisionDate(lastRevision)),
            .httpSuccess(testData: .syncWithCipher),
        ]
        stateService.activeAccount = .fixture()
        let lastSync = timeProvider.presentTime.addingTimeInterval(-(Constants.minimumSyncInterval + 60))
        stateService.lastSyncTimeByUserId["1"] = try XCTUnwrap(
            lastSync
        )
        keyConnectorService.userNeedsMigrationResult = .success(false)

        try await subject.fetchSync(forceSync: false, isPeriodic: true)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(cipherService.replaceCiphersCiphers)

        try XCTAssertEqual(
            XCTUnwrap(stateService.lastSyncTimeByUserId["1"]),
            timeProvider.presentTime
        )
    }

    /// `fetchSync()` doesn't sync if the last sync time is within the last 30 minutes and is periodic.
    func test_fetchSync_needsSync_lastSyncTime_newer30Mins() async throws {
        client.result = .httpSuccess(testData: .syncWithCipher)
        stateService.activeAccount = .fixture()
        stateService.lastSyncTimeByUserId["1"] = try XCTUnwrap(
            timeProvider.presentTime.addingTimeInterval(-(Constants.minimumSyncInterval - 1))
        )
        keyConnectorService.userNeedsMigrationResult = .success(false)

        try await subject.fetchSync(forceSync: false, isPeriodic: true)

        XCTAssertTrue(client.requests.isEmpty)
        XCTAssertNil(cipherService.replaceCiphersCiphers)
    }

    /// `fetchSync()` syncs if the last sync time is not greater than 30 minutes ago, is not periodic
    /// and the account has newer revisions.
    func test_fetchSync_notPeriodicNotOlder30MinsWithRevisions() async throws {
        client.results = [
            .httpSuccess(testData: .accountRevisionDate(timeProvider.presentTime)),
            .httpSuccess(testData: .syncWithCipher),
        ]
        stateService.activeAccount = .fixture()
        let lastSync = timeProvider.presentTime.addingTimeInterval(-(Constants.minimumSyncInterval - 1))
        stateService.lastSyncTimeByUserId["1"] = try XCTUnwrap(
            lastSync
        )
        keyConnectorService.userNeedsMigrationResult = .success(false)

        try await subject.fetchSync(forceSync: false, isPeriodic: false)

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertNotNil(cipherService.replaceCiphersCiphers)

        try XCTAssertEqual(
            XCTUnwrap(stateService.lastSyncTimeByUserId["1"]),
            timeProvider.presentTime
        )
    }

    /// `fetchSync()` syncs if there's no existing last sync time.
    func test_fetchSync_needsSync_noLastSyncTime() async throws {
        client.result = .httpSuccess(testData: .syncWithCipher)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync(forceSync: false)

        XCTAssertFalse(client.requests.isEmpty)
        XCTAssertNotNil(cipherService.replaceCiphersCiphers)
    }

    /// `fetchSync()` replaces the list of the user's ciphers.
    func test_fetchSync_ciphers() async throws {
        client.result = .httpSuccess(testData: .syncWithCipher)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync(forceSync: false)

        let date = Date(year: 2023, month: 8, day: 10, hour: 8, minute: 33, second: 45, nanosecond: 345_000_000)
        XCTAssertEqual(
            cipherService.replaceCiphersCiphers,
            [
                CipherDetailsResponseModel.fixture(
                    creationDate: date,
                    edit: true,
                    id: "3792af7a-4441-11ee-be56-0242ac120002",
                    login: .fixture(
                        fido2Credentials: [
                            CipherLoginFido2Credential(
                                counter: "encrypted counter",
                                creationDate: Date(timeIntervalSince1970: 1_710_523_862.244),
                                credentialId: "encrypted credentialId",
                                discoverable: "encrypted discoverable",
                                keyAlgorithm: "encrypted keyAlgorithm",
                                keyCurve: "encrypted keyCurve",
                                keyType: "encrypted keyType",
                                keyValue: "encrypted keyValue",
                                rpId: "encrypted rpId",
                                rpName: "encrypted rpName",
                                userDisplayName: "encrypted userDisplayName",
                                userHandle: "encrypted userHandle",
                                userName: "encrypted userName"
                            ),
                        ],
                        password: "encrypted password",
                        totp: "totp",
                        uris: [
                            CipherLoginUriModel(
                                match: nil,
                                uri: "encrypted uri",
                                uriChecksum: "encrypted uri checksum"
                            ),
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

        try await subject.fetchSync(forceSync: false)

        XCTAssertEqual(
            collectionService.replaceCollectionsCollections,
            [
                CollectionDetailsResponseModel.fixture(
                    id: "f96de98e-618a-4886-b396-66b92a385325",
                    name: "Engineering",
                    organizationId: "ba756e34-4650-4e8a-8cbb-6e98bfae9abf"
                ),
                CollectionDetailsResponseModel.fixture(
                    id: "1a102336-fbfd-4d63-bd7b-8a953a1bcdb3",
                    name: "Engineering/Apple",
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

        try await subject.fetchSync(forceSync: false)

        XCTAssertEqual(
            stateService.updateProfileResponse,
            .fixture(
                culture: "en-US",
                email: "user@bitwarden.com",
                id: "c8aa1e36-4427-11ee-be56-0242ac120002",
                key: "key",
                organizations: [],
                privateKey: "private key",
                securityStamp: "stamp"
            )
        )
        XCTAssertEqual(stateService.updateProfileUserId, "1")
        XCTAssertEqual(stateService.usesKeyConnector["1"], false)
    }

    /// `fetchSync()` notifies the sync service delegate if the user needs to be migrated to Key
    /// Connector.
    func test_fetchSync_removeMasterPassword() async throws {
        client.result = .httpSuccess(testData: .syncWithProfile)
        keyConnectorService.getManagingOrganizationResult = .success(
            .fixture(keyConnectorUrl: "htttp://example.com/", name: "Example Org"))
        keyConnectorService.userNeedsMigrationResult = .success(true)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync(forceSync: false)

        XCTAssertTrue(syncServiceDelegate.removeMasterPasswordCalled)
        XCTAssertEqual(syncServiceDelegate.removeMasterPasswordOrganizationName, "Example Org")
        XCTAssertEqual(syncServiceDelegate.removeMasterPasswordKeyConnectorUrl, "htttp://example.com/")
    }

    /// `fetchSync()` throws an error if checking if the user needs to be migrated fails.
    func test_fetchSync_removeMasterPassword_failure() async throws {
        client.result = .httpSuccess(testData: .syncWithProfile)
        keyConnectorService.userNeedsMigrationResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = .fixture()

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.fetchSync(forceSync: false)
        }

        XCTAssertFalse(syncServiceDelegate.removeMasterPasswordCalled)
    }

    /// `fetchSync()` notifies the sync service delegate if the security stamp changes and doesn't
    /// replace any of the user's data.
    func test_fetchSync_securityStampChanged() async throws {
        client.result = .httpSuccess(testData: .syncWithProfile)
        stateService.activeAccount = .fixture(profile: .fixture(stamp: "old stamp"))

        try await subject.fetchSync(forceSync: false)

        XCTAssertTrue(syncServiceDelegate.securityStampChangedCalled)
        XCTAssertEqual(syncServiceDelegate.securityStampChangedUserId, "1")
        XCTAssertNil(stateService.updateProfileResponse)
    }

    /// `fetchSync()` does not notify the sync service delegate if the security stamp is the same
    /// and syncs the user's data.
    func test_fetchSync_securityStampSame() async throws {
        client.result = .httpSuccess(testData: .syncWithProfile)
        stateService.activeAccount = .fixture(profile: .fixture(stamp: "stamp"))

        try await subject.fetchSync(forceSync: false)

        XCTAssertFalse(syncServiceDelegate.securityStampChangedCalled)
        XCTAssertNotNil(stateService.updateProfileResponse)
    }

    /// `fetchSync()` replaces the list of the user's sends.
    func test_fetchSync_sends() async throws {
        client.result = .httpSuccess(testData: .syncWithSends)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync(forceSync: false)

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

        try await subject.fetchSync(forceSync: false)

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

        try await subject.fetchSync(forceSync: false)

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

        try await subject.fetchSync(forceSync: false)

        XCTAssertTrue(organizationService.initializeOrganizationCryptoWithOrgsCalled)
        XCTAssertEqual(organizationService.replaceOrganizationsOrganizations?.count, 2)
        XCTAssertEqual(organizationService.replaceOrganizationsOrganizations?[0].id, "ORG_1")
        XCTAssertEqual(organizationService.replaceOrganizationsOrganizations?[1].id, "ORG_2")
        XCTAssertEqual(organizationService.replaceOrganizationsUserId, "1")
    }

    /// `fetchSync()` replaces the list of the user's organizations but doesn't initialize
    /// organization crypto if the user's vault is locked.
    @MainActor
    func test_fetchSync_organizations_vaultLocked() async throws {
        client.result = .httpSuccess(testData: .syncWithProfileOrganizations)
        stateService.activeAccount = .fixture()
        vaultTimeoutService.isClientLocked["1"] = true

        try await subject.fetchSync(forceSync: false)

        XCTAssertFalse(organizationService.initializeOrganizationCryptoWithOrgsCalled)
        XCTAssertEqual(organizationService.replaceOrganizationsOrganizations?.count, 2)
        XCTAssertEqual(organizationService.replaceOrganizationsOrganizations?[0].id, "ORG_1")
        XCTAssertEqual(organizationService.replaceOrganizationsOrganizations?[1].id, "ORG_2")
        XCTAssertEqual(organizationService.replaceOrganizationsUserId, "1")
    }

    /// `fetchSync()` replaces the list of the user's policies.
    func test_fetchSync_polices() async throws {
        client.result = .httpSuccess(testData: .syncWithPolicies)
        stateService.activeAccount = .fixture()

        try await subject.fetchSync(forceSync: false)

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
            try await subject.fetchSync(forceSync: false)
        }
        XCTAssertNil(syncServiceDelegate.onFetchSyncSucceededCalledWithuserId)
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
        cipherService.fetchAllCiphersResult = .success([
            .fixture(folderId: "id", id: "1"),
            .fixture(folderId: "other", id: "2"),
        ])
        cipherService.updateCipherWithLocalStorageResult = .success(())

        let notification = SyncFolderNotification(
            id: "id",
            revisionDate: nil,
            userId: "1"
        )
        try await subject.deleteFolder(data: notification)
        XCTAssertEqual(folderService.deleteFolderWithLocalStorageId, "id")
        XCTAssertEqual(
            cipherService.updateCipherWithLocalStorageCiphers,
            [.fixture(folderId: nil, id: "1")]
        )
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

    /// `needsSync(forceSync:onlyCheckLocalData:userId:)` returns `true` when
    /// only checking local data and not enough time hasn't passed since the last sync.
    func test_needsSync_onlyCheckLocalData() async throws {
        stateService.activeAccount = .fixture()
        let lastSync = timeProvider.presentTime.addingTimeInterval(-(Constants.minimumSyncInterval + 1))
        stateService.lastSyncTimeByUserId["1"] = try XCTUnwrap(
            lastSync
        )
        let needsSync = try await subject.needsSync(for: "1", onlyCheckLocalData: true)
        XCTAssertTrue(needsSync)
        XCTAssertTrue(client.requests.isEmpty)
    }
}

class MockSyncServiceDelegate: SyncServiceDelegate {
    var onFetchSyncSucceededCalledWithuserId: String?
    var removeMasterPasswordCalled = false
    var removeMasterPasswordOrganizationName: String?
    var securityStampChangedCalled = false
    var securityStampChangedUserId: String?
    var setMasterPasswordCalled = false
    var setMasterPasswordOrgId: String?
    var removeMasterPasswordOrganizationId: String?
    var removeMasterPasswordKeyConnectorUrl: String?

    func onFetchSyncSucceeded(userId: String) async {
        onFetchSyncSucceededCalledWithuserId = userId
    }

    func removeMasterPassword(organizationName: String, organizationId: String, keyConnectorUrl: String) {
        removeMasterPasswordOrganizationName = organizationName
        removeMasterPasswordOrganizationId = organizationId
        removeMasterPasswordKeyConnectorUrl = keyConnectorUrl
        removeMasterPasswordCalled = true
    }

    func securityStampChanged(userId: String) async {
        securityStampChangedCalled = true
        securityStampChangedUserId = userId
    }

    func setMasterPassword(orgIdentifier: String) async {
        setMasterPasswordCalled = true
        setMasterPasswordOrgId = orgIdentifier
    }
} // swiftlint:disable:this file_length
