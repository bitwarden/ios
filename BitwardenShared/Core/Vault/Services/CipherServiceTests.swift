import BitwardenSdk
import XCTest

@testable import BitwardenShared

class CipherServiceTests: XCTestCase {
    // MARK: Properties

    var cipherAPIService: CipherAPIService!
    var cipherDataStore: MockCipherDataStore!
    var client: MockHTTPClient!
    var stateService: MockStateService!
    var subject: CipherService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        client = MockHTTPClient()
        cipherAPIService = APIService(client: client)
        cipherDataStore = MockCipherDataStore()
        stateService = MockStateService()

        subject = DefaultCipherService(
            cipherAPIService: cipherAPIService,
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

    /// `ciphersPublisher()` returns a publisher that emits data as the data store changes.
    func test_ciphersPublisher() async throws {
        stateService.activeAccount = .fixtureAccountLogin()

        var iterator = try await subject.ciphersPublisher().values.makeAsyncIterator()
        _ = try await iterator.next()

        let cipher = Cipher.fixture()
        cipherDataStore.cipherSubject.value = [cipher]
        let publisherValue = try await iterator.next()
        try XCTAssertEqual(XCTUnwrap(publisherValue), [cipher])
    }

    /// `deleteCipherWithServer(id:)` deletes the cipher item from remote server and persisted cipher in the data store.
    func test_deleteCipher() async throws {
        stateService.accounts = [.fixtureAccountLogin()]
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: APITestData(data: Data()))
        try await subject.deleteCipherWithServer(id: "TestId")
        XCTAssertEqual(cipherDataStore.deleteCipherId, "TestId")
        XCTAssertEqual(cipherDataStore.deleteCipherUserId, "13512467-9cfe-43b0-969f-07534084764b")
    }

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

    /// `softDeleteCipherWithServer(id:)` soft deletes the cipher item
    /// from remote server and persisted cipher in the data store.
    func test_softDeleteCipher() async throws {
        stateService.accounts = [.fixtureAccountLogin()]
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: APITestData(data: Data()))
        let cipherToDeleted = Cipher.fixture(deletedDate: .now, id: "123")
        try await subject.softDeleteCipherWithServer(id: "123", cipherToDeleted)
        XCTAssertEqual(cipherDataStore.upsertCipherUserId, "13512467-9cfe-43b0-969f-07534084764b")
        XCTAssertEqual(cipherDataStore.upsertCipherValue, cipherToDeleted)
    }
}
