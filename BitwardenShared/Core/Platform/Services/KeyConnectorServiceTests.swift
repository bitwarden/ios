import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import BitwardenSdkMocks
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@MainActor
class KeyConnectorServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var client: MockHTTPClient!
    var clientRegistration: MockRegistrationClientProtocol!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var organizationService: MockOrganizationService!
    var subject: DefaultKeyConnectorService!
    var stateService: MockStateService!
    var tokenService: MockTokenService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        clientRegistration = MockRegistrationClientProtocol()
        clientService = MockClientService()
        configService = MockConfigService()
        organizationService = MockOrganizationService()
        stateService = MockStateService()
        tokenService = MockTokenService()

        clientRegistration.postKeysForKeyConnectorRegistrationReturnValue = KeyConnectorRegistrationResult(
            accountCryptographicState: .v2(
                privateKey: "private",
                signedPublicKey: "signedPublicKey",
                signingKey: "signingKey",
                securityState: "securityState",
            ),
            keyConnectorKey: "masterKey",
            keyConnectorKeyWrappedUserKey: "encryptedUserKey",
            userKey: "userKey",
        )
        clientService.mockAuth.makeKeyConnectorKeysReturnValue = KeyConnectorResponse(
            masterKey: "masterKey",
            encryptedUserKey: "encryptedUserKey",
            keys: RsaKeyPair(public: "public", private: "private"),
        )
        clientService.mockAuth.registrationReturnValue = clientRegistration
        configService.featureFlagsBool[.accountEncryptionV2KeyConnector] = true

        subject = DefaultKeyConnectorService(
            accountAPIService: APIService(client: client),
            clientService: clientService,
            configService: configService,
            keyConnectorAPIService: APIService(client: client),
            organizationService: organizationService,
            stateService: stateService,
            tokenService: tokenService,
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        client = nil
        clientService = nil
        configService = nil
        organizationService = nil
        subject = nil
        stateService = nil
        tokenService = nil
    }

    // MARK: Tests

    /// `convertNewUserToKeyConnector()` calls SDK registration and saves encryption keys.
    func test_convertNewUserToKeyConnector() async throws {
        stateService.activeAccount = .fixture()

        let result = try await subject.convertNewUserToKeyConnector(
            keyConnectorUrl: URL(string: "https://example.com/key-connector")!,
            orgIdentifier: "org-id",
        )

        XCTAssertEqual(result.masterKey, "masterKey")
        XCTAssertEqual(result.encryptedUserKey, "encryptedUserKey")
        XCTAssertTrue(clientRegistration.postKeysForKeyConnectorRegistrationCalled)
        XCTAssertEqual(
            clientRegistration.postKeysForKeyConnectorRegistrationReceivedArguments?.keyConnectorUrl,
            "https://example.com/key-connector",
        )
        XCTAssertEqual(
            clientRegistration.postKeysForKeyConnectorRegistrationReceivedArguments?.ssoOrgIdentifier,
            "org-id",
        )
        XCTAssertTrue(client.requests.isEmpty)
        XCTAssertNotNil(stateService.accountEncryptionKeys["1"]?.cryptographicState)
        XCTAssertNil(stateService.accountEncryptionKeys["1"]?.encryptedUserKey)
    }

    /// `convertNewUserToKeyConnector()` throws if SDK registration fails.
    func test_convertNewUserToKeyConnector_postKeysForKeyConnectorRegistrationFailure() async throws {
        clientRegistration.postKeysForKeyConnectorRegistrationThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.convertNewUserToKeyConnector(
                keyConnectorUrl: URL(string: "https://example.com/key-connector")!,
                orgIdentifier: "org-id",
            )
        }

        XCTAssertNil(stateService.accountEncryptionKeys["1"])
    }

    /// `convertNewUserToKeyConnector()` (v1) makes connector keys and uploads them to key connector and the API.
    func test_convertNewUserToKeyConnector_v1() async throws {
        configService.featureFlagsBool[.accountEncryptionV2KeyConnector] = false
        client.results = [
            .httpSuccess(testData: .emptyResponse),
            .httpSuccess(testData: .emptyResponse),
        ]
        stateService.activeAccount = .fixture()

        let result = try await subject.convertNewUserToKeyConnector(
            keyConnectorUrl: URL(string: "https://example.com/key-connector")!,
            orgIdentifier: "org-id",
        )

        XCTAssertEqual(result.masterKey, "masterKey")
        XCTAssertEqual(result.encryptedUserKey, "encryptedUserKey")
        XCTAssertTrue(clientService.mockAuth.makeKeyConnectorKeysCalled)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/key-connector/user-keys")!)
        XCTAssertEqual(client.requests[1].method, .post)
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/api/accounts/set-key-connector-key")!)
        XCTAssertEqual(
            stateService.accountEncryptionKeys["1"],
            AccountEncryptionKeys(
                cryptographicState: .v1(privateKey: "private"),
                encryptedUserKey: nil,
            ),
        )
    }

    /// `convertNewUserToKeyConnector()` (v1) throws an error if making key connector keys fails.
    func test_convertNewUserToKeyConnector_v1_makeKeyConnectorKeysFailure() async throws {
        configService.featureFlagsBool[.accountEncryptionV2KeyConnector] = false
        clientService.mockAuth.makeKeyConnectorKeysThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.convertNewUserToKeyConnector(
                keyConnectorUrl: URL(string: "https://example.com/key-connector")!,
                orgIdentifier: "org-id",
            )
        }

        XCTAssertTrue(clientService.mockAuth.makeKeyConnectorKeysCalled)
        XCTAssertTrue(client.requests.isEmpty)
        XCTAssertNil(stateService.accountEncryptionKeys["1"])
    }

    /// `convertNewUserToKeyConnector()` (v1) throws an error if uploading the keys fails.
    func test_convertNewUserToKeyConnector_v1_setKeyConnectorKeysFailure() async throws {
        configService.featureFlagsBool[.accountEncryptionV2KeyConnector] = false
        client.result = .httpFailure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.convertNewUserToKeyConnector(
                keyConnectorUrl: URL(string: "https://example.com/key-connector")!,
                orgIdentifier: "org-id",
            )
        }

        XCTAssertTrue(clientService.mockAuth.makeKeyConnectorKeysCalled)
        XCTAssertEqual(client.requests.count, 1)
    }

    /// `convertNewUserToKeyConnector()` (v1) throws an error if setting the account encryption keys fails.
    func test_convertNewUserToKeyConnector_v1_setAccountEncryptionKeysFailure() async throws {
        configService.featureFlagsBool[.accountEncryptionV2KeyConnector] = false
        client.results = [
            .httpSuccess(testData: .emptyResponse),
        ]

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.convertNewUserToKeyConnector(
                keyConnectorUrl: URL(string: "https://example.com/key-connector")!,
                orgIdentifier: "org-id",
            )
        }

        XCTAssertTrue(clientService.mockAuth.makeKeyConnectorKeysCalled)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/key-connector/user-keys")!)
        XCTAssertNil(stateService.accountEncryptionKeys["1"])
    }

    /// `migrateUser()` migrates the user keys and uploads them to the API and Key Connector.
    func test_migrateUser() async throws {
        let account = Account.fixture()
        client.results = [
            .httpSuccess(testData: .emptyResponse),
            .httpSuccess(testData: .emptyResponse),
        ]
        clientService.mockCrypto.deriveKeyConnectorReturnValue = "key"
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorEnabled: true, keyConnectorUrl: "https://example.com/key-connector"),
        ])
        stateService.activeAccount = account
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            cryptographicState: .v1(privateKey: "encryptedPrivateKey"),
            encryptedUserKey: "encryptedUserKey",
        )

        try await subject.migrateUser(
            password: "testPassword123",
        )

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/key-connector/user-keys")!)
        XCTAssertEqual(client.requests[1].method, .post)
        XCTAssertEqual(
            client.requests[1].url,
            URL(string: "https://example.com/api/accounts/convert-to-key-connector")!,
        )
        XCTAssertEqual(
            clientService.mockCrypto.deriveKeyConnectorReceivedRequest,
            DeriveKeyConnectorRequest(
                userKeyEncrypted: "encryptedUserKey",
                password: "testPassword123",
                kdf: account.kdf.sdkKdf,
                email: "user@bitwarden.com",
            ),
        )
        XCTAssertEqual(stateService.userHasMasterPassword["1"], false)
    }

    /// `migrateUser()` throws an error if there's no organization using key connector.
    func test_migrateUser_missingOrganization() async throws {
        organizationService.fetchAllOrganizationsResult = .success([])

        await assertAsyncThrows(error: KeyConnectorServiceError.missingOrganization) {
            try await subject.migrateUser(
                password: "testPassword123",
            )
        }
    }

    /// `migrateUser()` throws an error if the encrypted user key is missing.
    func test_migrateUser_missingEncryptedUserKey() async throws {
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorEnabled: true, keyConnectorUrl: "https://https://example.com/key-connector"),
        ])
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            cryptographicState: .v1(privateKey: "encryptedPrivateKey"),
            encryptedUserKey: nil,
        )

        await assertAsyncThrows(error: KeyConnectorServiceError.missingEncryptedUserKey) {
            try await subject.migrateUser(
                password: "testPassword123",
            )
        }
    }

    /// `migrateUser()` throws an error if deriving the key connector key fails.
    func test_migrateUser_deriveKeyConnectorError() async throws {
        clientService.mockCrypto.deriveKeyConnectorThrowableError = BitwardenTestError.example
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorEnabled: true, keyConnectorUrl: "https://https://example.com/key-connector"),
        ])
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            cryptographicState: .v1(privateKey: "encryptedPrivateKey"),
            encryptedUserKey: "encryptedUserKey",
        )

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.migrateUser(
                password: "testPassword123",
            )
        }
    }

    /// `migrateUser()` throws an error if a network request fails.
    func test_migrateUser_networkError() async throws {
        client.results = [
            .httpSuccess(testData: .emptyResponse),
            .httpFailure(URLError(.networkConnectionLost)),
        ]
        clientService.mockCrypto.deriveKeyConnectorReturnValue = "key"
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorEnabled: true, keyConnectorUrl: "https://https://example.com/key-connector"),
        ])
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            cryptographicState: .v1(privateKey: "encryptedPrivateKey"),
            encryptedUserKey: "encryptedUserKey",
        )

        await assertAsyncThrows(error: URLError(.networkConnectionLost)) {
            try await subject.migrateUser(
                password: "testPassword123",
            )
        }
    }

    /// `userNeedsMigration()` returns true if the user is external, their org uses key connector,
    /// but they don't.
    func test_userNeedsMigration_true() async throws {
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorEnabled: true),
        ])
        stateService.activeAccount = .fixture()
        stateService.usesKeyConnector["1"] = false
        tokenService.getIsExternalResult = .success(true)

        let needsMigration = try await subject.userNeedsMigration()

        XCTAssertTrue(needsMigration)
    }

    /// `userNeedsMigration()` returns false if the user isn't an organization member.
    func test_userNeedsMigration_false_noOrganizations() async throws {
        organizationService.fetchAllOrganizationsResult = .success([])
        stateService.activeAccount = .fixture()
        stateService.usesKeyConnector["1"] = false
        tokenService.getIsExternalResult = .success(true)

        let needsMigration = try await subject.userNeedsMigration()

        XCTAssertFalse(needsMigration)
    }

    /// `userNeedsMigration()` returns false if the user isn't an external user.
    func test_userNeedsMigration_false_notExternal() async throws {
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorEnabled: true),
        ])
        stateService.activeAccount = .fixture()
        stateService.usesKeyConnector["1"] = false
        tokenService.getIsExternalResult = .success(false)

        let needsMigration = try await subject.userNeedsMigration()

        XCTAssertFalse(needsMigration)
    }

    /// `userNeedsMigration()` returns false if the user is an organization admin.
    func test_userNeedsMigration_false_organizationsAdmin() async throws {
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorEnabled: true, type: .admin),
        ])
        stateService.activeAccount = .fixture()
        stateService.usesKeyConnector["1"] = false
        tokenService.getIsExternalResult = .success(true)

        let needsMigration = try await subject.userNeedsMigration()

        XCTAssertFalse(needsMigration)
    }

    /// `userNeedsMigration()` returns false if the user is an organization owner.
    func test_userNeedsMigration_false_organizationsOwner() async throws {
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorEnabled: true, type: .owner),
        ])
        stateService.activeAccount = .fixture()
        stateService.usesKeyConnector["1"] = false
        tokenService.getIsExternalResult = .success(true)

        let needsMigration = try await subject.userNeedsMigration()

        XCTAssertFalse(needsMigration)
    }

    /// `userNeedsMigration()` returns false if the user already uses Key Connector.
    func test_userNeedsMigration_false_usesKeyConnector() async throws {
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorEnabled: true),
        ])
        stateService.activeAccount = .fixture()
        stateService.usesKeyConnector["1"] = true
        tokenService.getIsExternalResult = .success(true)

        let needsMigration = try await subject.userNeedsMigration()

        XCTAssertFalse(needsMigration)
    }
}
