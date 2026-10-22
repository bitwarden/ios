import XCTest

@testable import BitwardenShared

class RegisterAgentAccessIdentityRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: RegisterAgentAccessIdentityRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = RegisterAgentAccessIdentityRequest(requestBody: .init(fingerprint: "abc123"))
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `body` returns the data for the request.
    func test_body() throws {
        let bodyData = try XCTUnwrap(subject.body?.encode())
        XCTAssertEqual(
            String(data: bodyData, encoding: .utf8),
            "{\"fingerprint\":\"abc123\"}",
        )
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .put)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/agent-access/identities")
    }
}
