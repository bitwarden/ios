import XCTest

@testable import BitwardenShared

// MARK: - RemovePasswordFromSendRequestTests

class RemovePasswordFromSendRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `path` returns the correct path.
    func test_path() {
        let subject = RemovePasswordFromSendRequest(sendId: "SEND_ID")
        XCTAssertEqual(subject.path, "/sends/SEND_ID/remove-password")
    }

    /// `method` is `.put`.
    func test_method() {
        let subject = RemovePasswordFromSendRequest(sendId: "SEND_ID")
        XCTAssertEqual(subject.method, .put)
    }
}
