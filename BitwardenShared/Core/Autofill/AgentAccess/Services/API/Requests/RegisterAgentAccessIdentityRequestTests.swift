import XCTest

@testable import BitwardenShared

class RegisterAgentAccessIdentityRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: RegisterAgentAccessIdentityRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = RegisterAgentAccessIdentityRequest(
            requestBody: .init(fingerprint: "abc123", publicKey: "cHVi", signature: "c2ln"),
        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `body` returns the data for the request.
    func test_body() throws {
        let bodyData = try XCTUnwrap(subject.body?.encode())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        XCTAssertEqual(json, ["fingerprint": "abc123", "publicKey": "cHVi", "signature": "c2ln"])
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
