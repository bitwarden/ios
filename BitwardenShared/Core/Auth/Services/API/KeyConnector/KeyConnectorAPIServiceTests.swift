import XCTest

@testable import BitwardenShared

class KeyConnectorAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: APIService!

    // MARK: Setup & Teardown

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

    /// `getMasterKeyFromKeyConnector(keyConnectorUrl:)` returns the user's key.
    func test_getMasterKeyFromKeyConnector() async throws {
        client.result = .httpSuccess(testData: .keyConnectorUserKey)

        let key = try await subject.getMasterKeyFromKeyConnector(
            keyConnectorUrl: URL(string: "https://example.com")!
        )
        XCTAssertEqual(key, "EXsYYd2Wx4H/9dhzmINS0P30lpG8bZ44RRn/T15tVA8=")

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.relativePath, "/user-keys")
    }

    /// `getMasterKeyFromKeyConnector(keyConnectorUrl:)` throws an error if the request fails.
    func test_getMasterKeyFromKeyConnector_httpFailure() async throws {
        client.result = .httpFailure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getMasterKeyFromKeyConnector(
                keyConnectorUrl: URL(string: "https://example.com")!
            )
        }
    }

    /// `postMasterKeyToKeyConnector(keyConnectorUrl:)` sends the user's key to the API.
    func test_postMasterKeyToKeyConnector() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        await assertAsyncDoesNotThrow {
            try await subject.postMasterKeyToKeyConnector(
                key: "🔑",
                keyConnectorUrl: URL(string: "https://example.com")!
            )
        }

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.relativePath, "/user-keys")
        XCTAssertNotNil(request.body)
    }

    /// `postMasterKeyToKeyConnector(keyConnectorUrl:)` throws an error if the request fails.
    func test_postMasterKeyToKeyConnector_httpFailure() async throws {
        client.result = .httpFailure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.postMasterKeyToKeyConnector(
                key: "🔑",
                keyConnectorUrl: URL(string: "https://example.com")!
            )
        }
    }
}
