import XCTest

@testable import BitwardenShared

class EventRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `body` is encoded events
    func test_body() throws {
        let date = Date(year: 2024, month: 6, day: 28)
        let events = [
            EventRequestModel(type: .cipherClientViewed, cipherId: "1", date: date),
            EventRequestModel(type: .cipherClientViewed, cipherId: "2", date: date.addingTimeInterval(1)),
        ]

        let subject = EventRequest(requestBody: events)

        XCTAssertEqual(subject.method, .post)
        XCTAssertEqual(subject.path, "/collect")
        XCTAssertNotNil(subject.body)
        XCTAssertEqual(subject.body, events)
    }
}
