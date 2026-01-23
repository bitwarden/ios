import TestHelpers
import XCTest

@testable import BitwardenShared

class EventAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: EventAPIService!

    // MARK: Set Up & Tear Down

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

    /// `postEvents(:)` sends events to the server.
    func test_postEvents() async throws {
        let date = Date(year: 2024, month: 6, day: 28)

        client.result = .httpSuccess(testData: .emptyResponse)

        _ = try await subject.postEvents([
            EventData(type: .cipherClientViewed, cipherId: "1", organizationId: nil, date: date),
            EventData(type: .cipherClientViewed, cipherId: "2", organizationId: nil, date: date.addingTimeInterval(1)),
        ])

        XCTAssertEqual(client.requests.count, 1)
        let request = try XCTUnwrap(client.requests.last)
        let data = try XCTUnwrap(request.body)
        XCTAssertEqual(
            try? JSONDecoder.defaultDecoder.decode([EventRequestModel].self, from: data),
            [
                EventRequestModel(type: .cipherClientViewed, cipherId: "1", organizationId: nil, date: date),
                EventRequestModel(type: .cipherClientViewed, cipherId: "2", organizationId: nil, date: date.addingTimeInterval(1)),
            ],
        )
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/events/collect")
    }

    /// `postEvents(:)` sends events with organizationId to the server.
    func test_postEvents_withOrganizationId() async throws {
        let date = Date(year: 2024, month: 6, day: 28)

        client.result = .httpSuccess(testData: .emptyResponse)

        _ = try await subject.postEvents([
            EventData(type: .cipherClientViewed, cipherId: "1", organizationId: "org-123", date: date),
            EventData(type: .userLoggedIn, cipherId: nil, organizationId: "org-456", date: date.addingTimeInterval(1)),
        ])

        XCTAssertEqual(client.requests.count, 1)
        let request = try XCTUnwrap(client.requests.last)
        let data = try XCTUnwrap(request.body)
        XCTAssertEqual(
            try? JSONDecoder.defaultDecoder.decode([EventRequestModel].self, from: data),
            [
                EventRequestModel(type: .cipherClientViewed, cipherId: "1", organizationId: "org-123", date: date),
                EventRequestModel(type: .userLoggedIn, cipherId: nil, organizationId: "org-456", date: date.addingTimeInterval(1)),
            ],
        )
    }
}
