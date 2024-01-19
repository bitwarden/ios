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

    /// `addCipherWithServer(_:)` adds the cipher in the backend and local storage.
    func test_addCipherWithServer() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: .cipherResponse)

        try await subject.addCipherWithServer(.fixture())

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers")
        XCTAssertEqual(cipherDataStore.upsertCipherValue?.id, "3792af7a-4441-11ee-be56-0242ac120002")
    }

    /// `addCipherWithServer(_:)` adds the cipher in the backend and local storage.
    func test_addCipherWithServer_withCollections() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: .cipherResponse)

        let cipher = Cipher.fixture(collectionIds: ["1"])
        try await subject.addCipherWithServer(cipher)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/create")
        XCTAssertEqual(cipherDataStore.upsertCipherValue?.collectionIds, ["1"])
        XCTAssertEqual(cipherDataStore.upsertCipherValue?.id, "3792af7a-4441-11ee-be56-0242ac120002")
    }

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

    /// `deleteAttachmentWithServer(attachmentId:cipherId:)` deletes the cipher's attachment from backend
    ///  and local storage.
    func test_deleteAttachmentWithServer() async throws {
        stateService.activeAccount = .fixture()
        cipherDataStore.fetchCipherResult = .fixture(attachments: [.fixture(id: "456")])
        client.result = .httpSuccess(testData: .emptyResponse)

        let updatedCipher = try await subject.deleteAttachmentWithServer(attachmentId: "456", cipherId: "123")

        XCTAssertEqual(cipherDataStore.upsertCipherValue, .fixture(attachments: []))
        XCTAssertEqual(updatedCipher, .fixture(attachments: []))
    }

    /// `deleteCipherWithServer(id:)` deletes the cipher item from remote server and persisted cipher in the data store.
    func test_deleteCipherWithServer() async throws {
        stateService.accounts = [.fixtureAccountLogin()]
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: .emptyResponse)

        try await subject.deleteCipherWithServer(id: "TestId")

        XCTAssertEqual(cipherDataStore.deleteCipherId, "TestId")
        XCTAssertEqual(cipherDataStore.deleteCipherUserId, "13512467-9cfe-43b0-969f-07534084764b")
    }

    /// `fetchCipher(withId:)` returns the cipher if it exists and nil otherwise.
    func test_fetchCipher() async throws {
        stateService.activeAccount = .fixture()

        var cipher = try await subject.fetchCipher(withId: "1")
        XCTAssertNil(cipher)
        XCTAssertEqual(cipherDataStore.fetchCipherId, "1")

        let testCipher = Cipher.fixture(id: "2")
        cipherDataStore.fetchCipherResult = testCipher

        cipher = try await subject.fetchCipher(withId: "2")
        XCTAssertEqual(cipher, testCipher)
        XCTAssertEqual(cipherDataStore.fetchCipherId, "2")
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

    /// `restoreCipherWithServer(id:_:)` restores the cipher in the backend and local storage.
    func test_restoreCipherWithServer() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)
        stateService.activeAccount = .fixture()

        try await subject.restoreCipherWithServer(id: "1", .fixture())

        XCTAssertEqual(cipherDataStore.upsertCipherValue, .fixture())
        XCTAssertEqual(cipherDataStore.upsertCipherUserId, "1")
    }

    /// `saveAttachmentWithServer(cipherId:attachment:)` calls the backend and updates the attachment list of
    /// the cipher in local storage.
    func test_saveAttachmentWithServer() async throws {
        client.result = .httpSuccess(testData: .saveAttachment)
        stateService.activeAccount = .fixture()

        let cipherResponse = try await subject.saveAttachmentWithServer(
            cipherId: "1",
            attachment: .init(attachment: .fixture(), contents: Data())
        )

        XCTAssertEqual(cipherDataStore.upsertCipherValue, cipherResponse)
        XCTAssertEqual(cipherDataStore.upsertCipherUserId, "1")
        XCTAssertEqual(cipherResponse.attachments?.count, 1)
    }

    /// `shareCipherWithServer(_:)` shares the cipher with the organization and updates the data store.
    func test_shareCipherWithServer() async throws {
        client.result = .httpSuccess(testData: .cipherResponse)
        stateService.activeAccount = .fixture()

        let cipher = Cipher.fixture(collectionIds: ["1", "2"], id: "123")
        try await subject.shareCipherWithServer(cipher)

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
        client.result = .httpSuccess(testData: .emptyResponse)
        let cipherToDeleted = Cipher.fixture(deletedDate: .now, id: "123")

        try await subject.softDeleteCipherWithServer(id: "123", cipherToDeleted)

        XCTAssertEqual(cipherDataStore.upsertCipherUserId, "13512467-9cfe-43b0-969f-07534084764b")
        XCTAssertEqual(cipherDataStore.upsertCipherValue, cipherToDeleted)
    }

    /// `updateCipherCollectionsWithServer(_:)` updates the cipher's collections and updates the data store.
    func test_updateCipherCollections() async throws {
        client.result = .success(.success())
        stateService.activeAccount = .fixture()

        let cipher = Cipher.fixture(collectionIds: ["1", "2"], id: "123")
        try await subject.updateCipherCollectionsWithServer(cipher)

        XCTAssertEqual(cipherDataStore.upsertCipherValue, cipher)
        XCTAssertEqual(cipherDataStore.upsertCipherUserId, "1")
    }

    /// `updateCipherWithServer(_:)` updates the cipher in the backend and local storage.
    func test_updateCipherWithServer() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: .cipherResponse)

        try await subject.updateCipherWithServer(.fixture(id: "123"))

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/123")
        XCTAssertEqual(cipherDataStore.upsertCipherValue?.id, "3792af7a-4441-11ee-be56-0242ac120002")
    }

    /// `updateCipherWithServer(_:)` updates the cipher with collections in the backend and local storage.
    func test_updateCipherWithServer_withCollections() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        client.result = .httpSuccess(testData: .cipherResponse)

        try await subject.updateCipherWithServer(.fixture(collectionIds: ["1", "2"], id: "123"))

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/123")
        XCTAssertEqual(cipherDataStore.upsertCipherValue?.collectionIds, ["1", "2"])
        XCTAssertEqual(cipherDataStore.upsertCipherValue?.id, "3792af7a-4441-11ee-be56-0242ac120002")
    }
}
