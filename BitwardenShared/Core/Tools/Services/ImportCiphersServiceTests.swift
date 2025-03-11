import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - ImportCiphersServiceTests

class ImportCiphersServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var importCiphersAPIService: ImportCiphersAPIService!
    var subject: ImportCiphersService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        importCiphersAPIService = APIService(client: client)
        subject = DefaultImportCiphersService(importCiphersAPIService: importCiphersAPIService)
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        importCiphersAPIService = nil
        subject = nil
    }

    // MARK: Tests

    /// `importCiphers(ciphers:folders:folderRelationships:)` import the ciphers calling the API.
    func test_importCiphers_succeeds() async throws {
        client.results = [.httpSuccess(testData: .emptyResponse)]
        try await subject.importCiphers(ciphers: [.fixture()], folders: [], folderRelationships: [])
        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/ciphers/import")
        XCTAssertEqual(request.method, .post)
    }

    /// `importCiphers(ciphers:folders:folderRelationships:)` throws when calling the API.
    func test_importCiphers_throws() async throws {
        client.results = [.httpFailure(BitwardenTestError.example)]
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.importCiphers(ciphers: [.fixture()], folders: [], folderRelationships: [])
        }
    }
}
