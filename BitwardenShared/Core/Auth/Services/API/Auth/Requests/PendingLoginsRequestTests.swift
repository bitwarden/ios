import Networking
import XCTest

@testable import BitwardenShared

class PendingLoginsRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: PendingLoginsRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = PendingLoginsRequest()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `body` is nil
    func test_body() throws {
        XCTAssertNil(subject.body)
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .get)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/auth-requests")
    }
}
