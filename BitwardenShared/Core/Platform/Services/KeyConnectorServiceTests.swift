import XCTest

@testable import BitwardenShared

class KeyConnectorServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: DefaultKeyConnectorService!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        stateService = MockStateService()

        subject = DefaultKeyConnectorService(
            keyConnectorAPIService: APIService(client: client),
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

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

        let key = try await subject.getMasterKeyFromKeyConnector()
        XCTAssertEqual(key, "EXsYYd2Wx4H/9dhzmINS0P30lpG8bZ44RRn/T15tVA8=")
    }

    /// `getMasterKeyFromKeyConnector()` throws an error if the key connector URL is missing.
    func test_getMasterKeyFromKeyConnector_missingUrl() async throws {
        stateService.activeAccount = .fixture()
        await assertAsyncThrows(error: KeyConnectorServiceError.missingKeyConnectorUrl) {
            _ = try await subject.getMasterKeyFromKeyConnector()
        }
    }
}
