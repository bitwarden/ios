import BitwardenSdk
import CoreData
import XCTest

@testable import BitwardenShared

class SendDataStoreTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DataStore!

    let sends = [
        Send.fixture(id: "1", name: "SEND1"),
        Send.fixture(id: "2", name: "SEND2"),
        Send.fixture(id: "3", name: "SEND3"),
    ]

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `deleteAllSends(user:)` removes all objects for the user.
    func test_deleteAllSends() async throws {
        try await insertSends(sends, userId: "1")
        try await insertSends(sends, userId: "2")

        try await subject.deleteAllSends(userId: "1")

        try XCTAssertTrue(fetchSends(userId: "1").isEmpty)
        try XCTAssertEqual(fetchSends(userId: "2").count, 3)
    }

    /// `deleteSend(id:userId:)` removes the send with the given ID for the user.
    func test_deleteSend() async throws {
        try await insertSends(sends, userId: "1")

        try await subject.deleteSend(id: "2", userId: "1")

        try XCTAssertEqual(
            fetchSends(userId: "1"),
            sends.filter { $0.id != "2" }
        )
    }

    /// `sendPublisher(userId:)` returns a publisher for a user's send objects.
    func test_sendPublisher() async throws {
        var publishedValues = [[Send]]()
        let publisher = subject.sendPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { values in
                    publishedValues.append(values)
                }
            )
        defer { publisher.cancel() }

        try await subject.replaceSends(sends, userId: "1")

        waitFor { publishedValues.count == 2 }
        XCTAssertTrue(publishedValues[0].isEmpty)
        XCTAssertEqual(publishedValues[1], sends)
    }

    /// `replaceSends(_:userId)` replaces the list of sends for the user.
    func test_replaceSends() async throws {
        try await insertSends(sends, userId: "1")

        let newSends = [
            Send.fixture(id: "3", name: "SEND3"),
            Send.fixture(id: "4", name: "SEND4"),
            Send.fixture(id: "5", name: "SEND5"),
        ]
        try await subject.replaceSends(newSends, userId: "1")

        XCTAssertEqual(try fetchSends(userId: "1"), newSends)
    }

    /// `upsertSend(_:userId:)` inserts a send for a user.
    func test_upsertSend_insert() async throws {
        let send = Send.fixture(id: "1")
        try await subject.upsertSend(send, userId: "1")

        try XCTAssertEqual(fetchSends(userId: "1"), [send])

        let send2 = Send.fixture(id: "2")
        try await subject.upsertSend(send2, userId: "1")

        try XCTAssertEqual(fetchSends(userId: "1"), [send, send2])
    }

    /// `upsertSend(_:userId:)` updates an existing send for a user.
    func test_upsertSend_update() async throws {
        try await insertSends(sends, userId: "1")

        let updatedSend = Send.fixture(id: "2", name: "UPDATED SEND2")
        try await subject.upsertSend(updatedSend, userId: "1")

        var expectedSends = sends
        expectedSends[1] = updatedSend

        try XCTAssertEqual(fetchSends(userId: "1"), expectedSends)
    }

    // MARK: Test Helpers

    /// A test helper to fetch all send's for a user.
    private func fetchSends(userId: String) throws -> [Send] {
        let fetchRequest = SendData.fetchByUserIdRequest(userId: userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SendData.id, ascending: true)]
        return try subject.backgroundContext.fetch(fetchRequest).map(Send.init)
    }

    /// A test helper for inserting a list of sends for a user.
    private func insertSends(_ sends: [Send], userId: String) async throws {
        try await subject.backgroundContext.performAndSave {
            for send in sends {
                _ = try SendData(context: self.subject.backgroundContext, userId: userId, send: send)
            }
        }
    }
}
