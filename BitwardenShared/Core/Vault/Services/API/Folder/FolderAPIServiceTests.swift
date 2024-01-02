import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class FolderAPIServiceTests: XCTestCase {
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

    /// `addFolder(name:)` performs the add folder request and decodes the response.
    func test_addFolder() async throws {
        client.result = .httpSuccess(testData: .folderResponse)

        let response = try await subject.addFolder(name: "Something Clever")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/folders")

        XCTAssertEqual(
            response,
            FolderResponseModel(
                id: "123456789",
                name: "Something Clever",
                revisionDate: Date(year: 2023, month: 12, day: 25)
            )
        )
    }

    /// `deleteFolder(id:)` performs the delete folder request and decodes the response.
    func test_deleteFolder() async throws {
        client.result = .httpSuccess(testData: APITestData(data: Data()))

        _ = try await subject.deleteFolder(withID: "123456789")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .delete)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/folders/123456789")
    }

    /// `editFolder(withID:name:)` performs the edit folder request and decodes the response.
    func test_editFolder() async throws {
        client.result = .httpSuccess(testData: .folderResponse)

        let response = try await subject.editFolder(withID: "123456789", name: "Something Clever")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .put)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/folders/123456789")

        XCTAssertEqual(
            response,
            FolderResponseModel(
                id: "123456789",
                name: "Something Clever",
                revisionDate: Date(year: 2023, month: 12, day: 25)
            )
        )
    }
}
