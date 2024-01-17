import BitwardenSdk
import XCTest

@testable import BitwardenShared

class SendServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var sendDataStore: MockSendDataStore!
    var stateService: MockStateService!
    var subject: SendService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        sendDataStore = MockSendDataStore()
        stateService = MockStateService()

        subject = DefaultSendService(
            sendAPIService: APIService(client: client),
            sendDataStore: sendDataStore,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()
        client = nil
        sendDataStore = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `addSend()` with a successful response uses the api service to send an add send request and
    /// save the result in the database.
    func test_addSend_success() async throws {
        stateService.activeAccount = .fixture()
        client.results = [
            .httpSuccess(testData: APITestData.sendResponse),
        ]

        let send = Send.fixture()
        try await subject.addSend(send)

        XCTAssertEqual(client.requests.count, 1)
    }

    /// `addSend()` with a failure response throws the encountered error.
    func test_addSend_failure() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        client.results = [
            .httpFailure(BitwardenTestError.example),
        ]

        let send = Send.fixture()
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.addSend(send)
        }

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(sendDataStore.upsertSendValue)
        XCTAssertNil(sendDataStore.upsertSendUserId)
    }

    /// `replaceSends(_:userId:)` replaces the persisted sends in the data store.
    func test_replaceSends() async throws {
        let sends: [SendResponseModel] = [
            SendResponseModel.fixture(id: "1", name: "Send 1"),
            SendResponseModel.fixture(id: "2", name: "Send 2"),
        ]

        try await subject.replaceSends(sends, userId: "1")

        XCTAssertEqual(sendDataStore.replaceSendsValue, sends.map(Send.init))
        XCTAssertEqual(sendDataStore.replaceSendsUserId, "1")
    }

    /// `updateSend()` with a successful response uses the api service to send an update send
    /// request and save the result in the database.
    func test_updateSend_success() async throws {
        stateService.activeAccount = .fixture()
        client.results = [
            .httpSuccess(testData: APITestData.sendResponse),
        ]

        let send = Send.fixture()
        try await subject.addSend(send)

        XCTAssertEqual(client.requests.count, 1)
    }

    /// `updateSend()` with a failure response throws the encountered error.
    func test_updateSend_failure() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        client.results = [
            .httpFailure(BitwardenTestError.example),
        ]

        let send = Send.fixture()
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.updateSend(send)
        }

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(sendDataStore.upsertSendValue)
        XCTAssertNil(sendDataStore.upsertSendUserId)
    }
}
