import XCTest

@testable import BitwardenShared

// MARK: - SendAPIServiceTests

class SendAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: APIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        client = MockHTTPClient()
        subject = APIService(client: client)
    }

    override func tearDown() {
        super.tearDown()
        client = nil
        subject = nil
    }

    // MARK: Tests

    /// `addSend()` performs the add send request and decodes the response.
    func test_addSend() async throws {
        client.results = [
            .httpSuccess(testData: .sendResponse),
        ]
        let response = try await subject.addSend(.fixture())

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/sends")

        XCTAssertEqual(
            response,
            SendResponseModel(
                accessCount: 0,
                accessId: "access id",
                deletionDate: Date(year: 2023, month: 8, day: 7, hour: 21, minute: 33),
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
                text: SendTextModel(
                    hidden: false,
                    text: "encrypted text"
                ),
                type: .text
            )
        )
    }
}
