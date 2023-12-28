import BitwardenSdk
import XCTest

@testable import BitwardenShared

class CipherServiceTests: XCTestCase {
    // MARK: Properties

    var cipherDataStore: MockCipherDataStore!
    var client: MockHTTPClient!
    var stateService: MockStateService!
    var subject: CipherService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherDataStore = MockCipherDataStore()
        client = MockHTTPClient()
        stateService = MockStateService()

        subject = DefaultCipherService(
            cipherAPIService: APIService(client: client),
            cipherDataStore: cipherDataStore,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherDataStore = nil
        client = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `replaceCiphers(_:userId:)` replaces the persisted ciphers in the data store.
    func test_replaceCiphers() async throws {
        let ciphers: [CipherDetailsResponseModel] = [
            CipherDetailsResponseModel.fixture(id: "1", name: "Cipher 1"),
            CipherDetailsResponseModel.fixture(id: "2", name: "Cipher 2"),
        ]

        try await subject.replaceCiphers(ciphers, userId: "1")

        XCTAssertEqual(cipherDataStore.replaceCiphersValue, ciphers.map(Cipher.init))
        XCTAssertEqual(cipherDataStore.replaceCiphersUserId, "1")
    }

    /// `shareCipher(_:)` shares the cipher with the organization and updates the data store.
    func test_shareCipher() async throws {
        client.result = .httpSuccess(testData: .cipherResponse)
        stateService.activeAccount = .fixture()

        let cipher = Cipher.fixture(collectionIds: ["1", "2"], id: "123")
        try await subject.shareWithServer(cipher)

        var cipherResponse = try CipherDetailsResponseModel(
            response: .success(body: APITestData.cipherResponse.data)
        )
        cipherResponse.collectionIds = ["1", "2"]
        XCTAssertEqual(cipherDataStore.upsertCipherValue, Cipher(responseModel: cipherResponse))
        XCTAssertEqual(cipherDataStore.upsertCipherUserId, "1")
    }
}
