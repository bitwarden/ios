import BitwardenSdk
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length type_body_length function_body_length

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
        let apiService = APIService(client: client)

        subject = DefaultSendService(
            fileAPIService: apiService,
            sendAPIService: apiService,
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

    /// `addFileSend()` with a successful response uses the api service to send an add send request and
    /// save the result in the database.
    func test_addFileSend_success() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "ID"))
        client.results = [
            .httpSuccess(testData: APITestData.sendFileResponse),
            .success(.success(statusCode: 201)),
        ]

        let send = Send.fixture()
        let data = Data("example".utf8)
        let result = try await subject.addFileSend(send, data: data)

        XCTAssertEqual(
            result,
            .fixture(
                accessCount: 0,
                accessId: "access id",
                deletionDate: Date(year: 2023, month: 8, day: 7, hour: 21, minute: 33, second: 0),
                disabled: false,
                expirationDate: nil,
                file: nil,
                hideEmail: false,
                id: "fc483c22-443c-11ee-be56-0242ac120002",
                key: "encrypted key",
                maxAccessCount: nil,
                name: "encrypted name",
                notes: nil,
                password: nil,
                revisionDate: Date(year: 2023, month: 8, day: 1, hour: 21, minute: 33, second: 31),
                text: .init(
                    hidden: false,
                    text: "encrypted text"
                ),
                type: .text
            )
        )
        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(
            sendDataStore.upsertSendValue,
            .fixture(
                accessCount: 0,
                accessId: "access id",
                deletionDate: Date(year: 2023, month: 8, day: 7, hour: 21, minute: 33, second: 0),
                disabled: false,
                expirationDate: nil,
                file: nil,
                hideEmail: false,
                id: "fc483c22-443c-11ee-be56-0242ac120002",
                key: "encrypted key",
                maxAccessCount: nil,
                name: "encrypted name",
                notes: nil,
                password: nil,
                revisionDate: Date(year: 2023, month: 8, day: 1, hour: 21, minute: 33, second: 31),
                text: .init(
                    hidden: false,
                    text: "encrypted text"
                ),
                type: .text
            )
        )
        XCTAssertEqual(sendDataStore.upsertSendUserId, "ID")
    }

    /// `addFileSend()` with a failure response throws the encountered error.
    func test_addFileSend_failure() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        client.results = [
            .httpFailure(BitwardenTestError.example),
        ]

        let send = Send.fixture()
        let data = Data("example".utf8)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.addFileSend(send, data: data)
        }

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(sendDataStore.upsertSendValue)
        XCTAssertNil(sendDataStore.upsertSendUserId)
    }

    /// `addFileSend()` with an upload failure deletes the send on the backend
    /// and throws the error.
    func test_addFileSend_success_uploadFailure() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "ID"))
        client.results = [
            .httpSuccess(testData: APITestData.sendFileResponse),
            .httpFailure(statusCode: 401),
            .success(.success()),
        ]

        let send = Send.fixture()
        let data = Data("example".utf8)
        await assertAsyncThrows {
            _ = try await subject.addFileSend(send, data: data)
        }

        XCTAssertEqual(client.requests.count, 3)
        XCTAssertNil(sendDataStore.upsertSendValue)
        XCTAssertNil(sendDataStore.upsertSendUserId)

        XCTAssertEqual(
            client.requests[2].url.absoluteString,
            "https://example.com/api/sends/fc483c22-443c-11ee-be56-0242ac120002"
        )
        XCTAssertEqual(client.requests[2].method, .delete)
    }

    /// `addTextSend()` with a successful response uses the api service to send an add send request and
    /// save the result in the database.
    func test_addTextSend_success() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "ID"))
        client.results = [
            .httpSuccess(testData: APITestData.sendResponse),
        ]

        let result = try await subject.addTextSend(.fixture())

        XCTAssertEqual(
            result,
            .fixture(
                accessCount: 0,
                accessId: "access id",
                deletionDate: Date(year: 2023, month: 8, day: 7, hour: 21, minute: 33, second: 0),
                disabled: false,
                expirationDate: nil,
                file: nil,
                hideEmail: false,
                id: "fc483c22-443c-11ee-be56-0242ac120002",
                key: "encrypted key",
                maxAccessCount: nil,
                name: "encrypted name",
                notes: nil,
                password: nil,
                revisionDate: Date(year: 2023, month: 8, day: 1, hour: 21, minute: 33, second: 31),
                text: .init(
                    hidden: false,
                    text: "encrypted text"
                ),
                type: .text
            )
        )
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            sendDataStore.upsertSendValue,
            .fixture(
                accessCount: 0,
                accessId: "access id",
                deletionDate: Date(year: 2023, month: 8, day: 7, hour: 21, minute: 33, second: 0),
                disabled: false,
                expirationDate: nil,
                file: nil,
                hideEmail: false,
                id: "fc483c22-443c-11ee-be56-0242ac120002",
                key: "encrypted key",
                maxAccessCount: nil,
                name: "encrypted name",
                notes: nil,
                password: nil,
                revisionDate: Date(year: 2023, month: 8, day: 1, hour: 21, minute: 33, second: 31),
                text: .init(
                    hidden: false,
                    text: "encrypted text"
                ),
                type: .text
            )
        )
        XCTAssertEqual(sendDataStore.upsertSendUserId, "ID")
    }

    /// `addTextSend()` with a failure response throws the encountered error.
    func test_addTextSend_failure() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        client.results = [
            .httpFailure(BitwardenTestError.example),
        ]

        let send = Send.fixture()
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.addTextSend(send)
        }

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(sendDataStore.deleteSendId)
        XCTAssertNil(sendDataStore.deleteSendUserId)
    }

    /// `deleteSend()` with a successful response uses the api service to send an add send request and
    /// save the result in the database.
    func test_deleteSend_success() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "USER_ID"))
        client.results = [
            .httpSuccess(testData: APITestData.sendResponse),
        ]

        try await subject.deleteSend(.fixture(id: "SEND_ID"))

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(sendDataStore.deleteSendId, "SEND_ID")
        XCTAssertEqual(sendDataStore.deleteSendUserId, "USER_ID")
    }

    /// `deleteSend()` with a failure response throws the encountered error.
    func test_deleteSend_failure() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        client.results = [
            .httpFailure(BitwardenTestError.example),
        ]

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.deleteSend(.fixture(id: "SEND_ID"))
        }

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(sendDataStore.deleteSendId)
        XCTAssertNil(sendDataStore.deleteSendUserId)
    }

    /// `deleteSend()` has no effect when the send provided has no id.
    func test_deleteSend_noSendId() async throws {
        let account = Account.fixture(profile: .fixture(userId: "USER_ID"))
        stateService.activeAccount = account

        try await subject.deleteSend(.fixture(id: nil))

        XCTAssertEqual(client.requests.count, 0)
        XCTAssertNil(sendDataStore.deleteSendId)
        XCTAssertNil(sendDataStore.deleteSendUserId)
    }

    /// `removePasswordFromSend()` performs the remove password request and updates the value in the
    /// data store.
    func test_removePasswordFromSend_success() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "USER_ID"))
        client.results = [
            .httpSuccess(testData: APITestData.sendResponse),
        ]

        let response = try await subject.removePasswordFromSend(.fixture(id: "SEND_ID"))

        XCTAssertEqual(response.id, "fc483c22-443c-11ee-be56-0242ac120002")
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            sendDataStore.upsertSendValue?.id,
            "fc483c22-443c-11ee-be56-0242ac120002"
        )
        XCTAssertEqual(sendDataStore.upsertSendUserId, "USER_ID")
    }

    /// `removePasswordFromSend()` performs the remove password request and updates the value in the
    /// data store.
    func test_removePasswordFromSend_failure() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "USER_ID"))
        client.result = .httpFailure()

        await assertAsyncThrows {
            _ = try await subject.removePasswordFromSend(.fixture(id: "SEND_ID"))
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

    /// `sendsPublisher()` returns a publisher for the list of sections and items that are
    /// displayed in the sends tab.
    func test_sendsPublisher_withValues() async throws {
        stateService.activeAccount = .fixtureAccountLogin()
        sendDataStore.sendSubject.send([.fixture()])

        var iterator = try await subject.sendsPublisher().values.makeAsyncIterator()
        let publisherValue = try await iterator.next()

        try XCTAssertEqual(XCTUnwrap(publisherValue), [.fixture()])
    }

    /// `updateSend()` with a successful response uses the api service to send an update send
    /// request and save the result in the database.
    func test_updateSend_success() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "ID"))
        client.results = [
            .httpSuccess(testData: APITestData.sendResponse),
        ]

        let send = Send.fixture()
        let result = try await subject.updateSend(send)

        XCTAssertEqual(
            result,
            .fixture(
                accessCount: 0,
                accessId: "access id",
                deletionDate: Date(year: 2023, month: 8, day: 7, hour: 21, minute: 33, second: 0),
                disabled: false,
                expirationDate: nil,
                file: nil,
                hideEmail: false,
                id: "fc483c22-443c-11ee-be56-0242ac120002",
                key: "encrypted key",
                maxAccessCount: nil,
                name: "encrypted name",
                notes: nil,
                password: nil,
                revisionDate: Date(year: 2023, month: 8, day: 1, hour: 21, minute: 33, second: 31),
                text: .init(
                    hidden: false,
                    text: "encrypted text"
                ),
                type: .text
            )
        )
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(
            sendDataStore.upsertSendValue,
            .fixture(
                accessCount: 0,
                accessId: "access id",
                deletionDate: Date(year: 2023, month: 8, day: 7, hour: 21, minute: 33, second: 0),
                disabled: false,
                expirationDate: nil,
                file: nil,
                hideEmail: false,
                id: "fc483c22-443c-11ee-be56-0242ac120002",
                key: "encrypted key",
                maxAccessCount: nil,
                name: "encrypted name",
                notes: nil,
                password: nil,
                revisionDate: Date(year: 2023, month: 8, day: 1, hour: 21, minute: 33, second: 31),
                text: .init(
                    hidden: false,
                    text: "encrypted text"
                ),
                type: .text
            )
        )
        XCTAssertEqual(sendDataStore.upsertSendUserId, "ID")
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
            _ = try await subject.updateSend(send)
        }

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(sendDataStore.upsertSendValue)
        XCTAssertNil(sendDataStore.upsertSendUserId)
    }
}

// swiftlint:enable file_length type_body_length function_body_length
