import BitwardenSdk
import XCTest

@testable import BitwardenShared

class KeyConnectorServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var client: MockHTTPClient!
    var clientService: MockClientService!
    var organizationService: MockOrganizationService!
    var subject: DefaultKeyConnectorService!
    var stateService: MockStateService!
    var tokenService: MockTokenService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        clientService = MockClientService()
        organizationService = MockOrganizationService()
        stateService = MockStateService()
        tokenService = MockTokenService()

        subject = DefaultKeyConnectorService(
            accountAPIService: APIService(client: client),
            clientService: clientService,
            keyConnectorAPIService: APIService(client: client),
            organizationService: organizationService,
            stateService: stateService,
            tokenService: tokenService
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        clientService = nil
        organizationService = nil
        subject = nil
        stateService = nil
        tokenService = nil
    }

    // MARK: Tests

    /// `convertNewUserToKeyConnector()` makes connector keys and uploads them to key connector and the API.
    func test_convertNewUserToKeyConnector() async throws {
        client.results = [
            .httpSuccess(testData: .emptyResponse),
            .httpSuccess(testData: .emptyResponse),
        ]
        stateService.activeAccount = .fixture()

        try await subject.convertNewUserToKeyConnector(
            keyConnectorUrl: URL(string: "https://example.com/key-connector")!,
            orgIdentifier: "org-id"
        )

        XCTAssertTrue(clientService.mockAuth.makeKeyConnectorKeysCalled)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/key-connector/user-keys")!)
        XCTAssertEqual(client.requests[1].method, .post)
        XCTAssertEqual(client.requests[1].url, URL(string: "https://example.com/api/accounts/set-key-connector-key")!)
        XCTAssertEqual(
            stateService.accountEncryptionKeys["1"],
            AccountEncryptionKeys(encryptedPrivateKey: "private", encryptedUserKey: "encryptedUserKey")
        )
    }

    /// `convertNewUserToKeyConnector()` throws an error if making key connector keys fails.
    func test_convertNewUserToKeyConnector_makeKeyConnectorKeysFailure() async throws {
        clientService.mockAuth.makeKeyConnectorKeysResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.convertNewUserToKeyConnector(
                keyConnectorUrl: URL(string: "https://example.com/key-connector")!,
                orgIdentifier: "org-id"
            )
        }

        XCTAssertTrue(clientService.mockAuth.makeKeyConnectorKeysCalled)
        XCTAssertTrue(client.requests.isEmpty)
        XCTAssertNil(stateService.accountEncryptionKeys["1"])
    }

    /// `convertNewUserToKeyConnector()` throws an error if uploading the keys fails.
    func test_convertNewUserToKeyConnector_setKeyConnectorKeysFailure() async throws {
        client.result = .httpFailure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.convertNewUserToKeyConnector(
                keyConnectorUrl: URL(string: "https://example.com/key-connector")!,
                orgIdentifier: "org-id"
            )
        }

        XCTAssertTrue(clientService.mockAuth.makeKeyConnectorKeysCalled)
        XCTAssertEqual(client.requests.count, 1)
    }

    /// `convertNewUserToKeyConnector()` throws an error if setting the account encryption keys fails.
    func test_convertNewUserToKeyConnector_setAccountEncryptionKeysFailure() async throws {
        client.results = [
            .httpSuccess(testData: .emptyResponse),
        ]

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.convertNewUserToKeyConnector(
                keyConnectorUrl: URL(string: "https://example.com/key-connector")!,
                orgIdentifier: "org-id"
            )
        }

        XCTAssertTrue(clientService.mockAuth.makeKeyConnectorKeysCalled)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/key-connector/user-keys")!)
        XCTAssertNil(stateService.accountEncryptionKeys["1"])
    }

    /// `getMasterKeyFromKeyConnector()` returns the user's master key from the Key Connector API.
    func test_getMasterKeyFromKeyConnector() async throws {
        client.result = .httpSuccess(testData: .keyConnectorUserKey)
        stateService.activeAccount = .fixture(
            profile: .fixture(
                userDecryptionOptions: UserDecryptionOptions(
                    hasMasterPassword: false,
                    keyConnectorOption: KeyConnectorUserDecryptionOption(keyConnectorUrl: "https://example.com"),
                    trustedDeviceOption: nil
                )
            )
        )

        let key = try await subject.getMasterKeyFromKeyConnector(
            keyConnectorUrl: URL(string: "https://example.com/key-connector")!
        )
        XCTAssertEqual(key, "EXsYYd2Wx4H/9dhzmINS0P30lpG8bZ44RRn/T15tVA8=")
    }

    /// `migrateUser()` migrates the user keys and uploads them to the API and Key Connector.
    func test_migrateUser() async throws {
        let account = Account.fixture()
        client.results = [
            .httpSuccess(testData: .emptyResponse),
            .httpSuccess(testData: .emptyResponse),
        ]
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorUrl: "https://example.com/key-connector", useKeyConnector: true),
        ])
        stateService.activeAccount = account
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            encryptedPrivateKey: "encryptedPrivateKey",
            encryptedUserKey: "encryptedUserKey"
        )

        try await subject.migrateUser(
            password: "testPassword123"
        )

        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/key-connector/user-keys")!)
        XCTAssertEqual(client.requests[1].method, .post)
        XCTAssertEqual(
            client.requests[1].url,
            URL(string: "https://example.com/api/accounts/convert-to-key-connector")!
        )
        XCTAssertEqual(
            clientService.mockCrypto.deriveKeyConnectorRequest,
            DeriveKeyConnectorRequest(
                userKeyEncrypted: "encryptedUserKey",
                password: "testPassword123",
                kdf: account.kdf.sdkKdf,
                email: "user@bitwarden.com"
            )
        )
    }

    /// `migrateUser()` throws an error if there's no organization using key connector.
    func test_migrateUser_missingOrganization() async throws {
        organizationService.fetchAllOrganizationsResult = .success([])

        await assertAsyncThrows(error: KeyConnectorServiceError.missingOrganization) {
            try await subject.migrateUser(
                password: "testPassword123"
            )
        }
    }

    /// `migrateUser()` throws an error if the encrypted user key is missing.
    func test_migrateUser_missingEncryptedUserKey() async throws {
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorUrl: "https://https://example.com/key-connector", useKeyConnector: true),
        ])
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            encryptedPrivateKey: "encryptedPrivateKey",
            encryptedUserKey: nil
        )

        await assertAsyncThrows(error: KeyConnectorServiceError.missingEncryptedUserKey) {
            try await subject.migrateUser(
                password: "testPassword123"
            )
        }
    }

    /// `migrateUser()` throws an error if deriving the key connector key fails.
    func test_migrateUser_deriveKeyConnectorError() async throws {
        clientService.mockCrypto.deriveKeyConnectorResult = .failure(BitwardenTestError.example)
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorUrl: "https://https://example.com/key-connector", useKeyConnector: true),
        ])
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            encryptedPrivateKey: "encryptedPrivateKey",
            encryptedUserKey: "encryptedUserKey"
        )

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.migrateUser(
                password: "testPassword123"
            )
        }
    }

    /// `migrateUser()` throws an error if a network request fails.
    func test_migrateUser_networkError() async throws {
        client.results = [
            .httpSuccess(testData: .emptyResponse),
            .httpFailure(URLError(.networkConnectionLost)),
        ]
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(keyConnectorUrl: "https://https://example.com/key-connector", useKeyConnector: true),
        ])
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            encryptedPrivateKey: "encryptedPrivateKey",
            encryptedUserKey: "encryptedUserKey"
        )

        await assertAsyncThrows(error: URLError(.networkConnectionLost)) {
            try await subject.migrateUser(
                password: "testPassword123"
            )
        }
    }

    /// `userNeedsMigration()` returns true if the user is external, their org uses key connector,
    /// but they don't.
    func test_userNeedsMigration_true() async throws {
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(useKeyConnector: true),
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
            .fixture(useKeyConnector: true),
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
            .fixture(type: .admin, useKeyConnector: true),
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
            .fixture(type: .owner, useKeyConnector: true),
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
            .fixture(useKeyConnector: true),
        ])
        stateService.activeAccount = .fixture()
        stateService.usesKeyConnector["1"] = true
        tokenService.getIsExternalResult = .success(true)

        let needsMigration = try await subject.userNeedsMigration()

        XCTAssertFalse(needsMigration)
    }
}
