import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - UpdateSendRequestTests

class UpdateSendRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(send:)` with a send id initializes the properties correctly.
    func test_init_send_withId() throws {
        let send = Send.fixture(id: "ID")
        let subject = try UpdateSendRequest(send: send)

        XCTAssertEqual(subject.path, "/sends/ID")
        XCTAssertEqual(subject.method, .put)
        XCTAssertEqual(subject.sendId, "ID")
    }

    /// `init(send:)` without a send id throws an error.
    func test_init_send_withoutId() {
        let send = Send.fixture(id: nil)
        XCTAssertThrowsError(try UpdateSendRequest(send: send)) { error in
            XCTAssertEqual(error as? UpdateSendRequestError, .noSendId)
        }
    }
}
