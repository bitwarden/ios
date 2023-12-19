import BitwardenSdk
import XCTest

@testable import BitwardenShared

class SendServiceTests: XCTestCase {
    // MARK: Properties

    var sendDataStore: MockSendDataStore!
    var subject: SendService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        sendDataStore = MockSendDataStore()

        subject = DefaultSendService(
            sendDataStore: sendDataStore,
            stateService: MockStateService()
        )
    }

    override func tearDown() {
        super.tearDown()

        sendDataStore = nil
        subject = nil
    }

    // MARK: Tests

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
}
