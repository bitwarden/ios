import TestHelpers
import XCTest

@testable import BitwardenShared

@MainActor
class AgentAccessAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: AgentAccessAPIService!

    // MARK: Set Up & Tear Down

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        subject = APIService(client: client)
    }

    override func tearDown() async throws {
        try await super.tearDown()

        client = nil
        subject = nil
    }

    // MARK: Tests

    /// `registerIdentity(proof:)` performs the register identity request.
    func test_registerIdentity() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        try await subject.registerIdentity(
            proof: AgentAccessIdentityProof(fingerprint: "abc123", publicKey: "cHVi", signature: "c2ln"),
        )

        XCTAssertEqual(client.requests.count, 1)
        let body = try XCTUnwrap(client.requests[0].body)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(json, ["fingerprint": "abc123", "publicKey": "cHVi", "signature": "c2ln"])
        XCTAssertEqual(client.requests[0].method, .put)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/agent-access/identities")
    }

    /// `unregisterIdentity(fingerprint:)` performs the unregister identity request.
    func test_unregisterIdentity() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        try await subject.unregisterIdentity(fingerprint: "abc123")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .delete)
        XCTAssertEqual(
            client.requests[0].url.absoluteString,
            "https://example.com/api/agent-access/identities/abc123",
        )
    }
}
