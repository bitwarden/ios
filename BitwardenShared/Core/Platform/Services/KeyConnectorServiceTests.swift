import XCTest

@testable import BitwardenShared

class KeyConnectorServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var clientService: MockClientService!
    var subject: DefaultKeyConnectorService!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        clientService = MockClientService()
        stateService = MockStateService()

        subject = DefaultKeyConnectorService(
            accountAPIService: APIService(client: client),
            clientService: clientService,
            keyConnectorAPIService: APIService(client: client),
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        clientService = nil
        subject = nil
        stateService = nil
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
}
