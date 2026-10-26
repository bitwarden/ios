import XCTest

@testable import BitwardenShared

class UnregisterAgentAccessIdentityRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: UnregisterAgentAccessIdentityRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = UnregisterAgentAccessIdentityRequest(fingerprint: "abc123")
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `body` is empty.
    func test_body() {
        XCTAssertNil(subject.body)
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .delete)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/agent-access/identities/abc123")
    }
}
