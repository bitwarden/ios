import Networking
import XCTest

@testable import BitwardenShared

class GetPlansRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: GetPlansRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = GetPlansRequest()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns a `nil` body.
    func test_body() throws {
        XCTAssertNil(subject.body)
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .get)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/plans")
    }
}
