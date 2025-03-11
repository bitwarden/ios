import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - ImportCiphersAPIServiceTests

class ImportCiphersAPIServiceTests: BitwardenTestCase {
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

    /// `importCiphers(ciphers:folders:folderRelationships:)` performs the import ciphers request.
    func test_importCiphers() async throws {
        client.results = [
            .httpSuccess(testData: .emptyResponse),
        ]
        _ = try await subject.importCiphers(ciphers: [.fixture()], folders: [], folderRelationships: [])

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/ciphers/import")
    }

    /// `importCiphers(ciphers:folders:folderRelationships:)` performs the import ciphers request.
    func test_importCiphers_throws() async throws {
        client.results = [
            .httpFailure(BitwardenTestError.example),
        ]

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.importCiphers(ciphers: [.fixture()], folders: [], folderRelationships: [])
        }
    }
}
