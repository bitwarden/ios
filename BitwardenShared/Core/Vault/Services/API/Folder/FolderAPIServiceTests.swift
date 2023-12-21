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

    /// `addFolder()` performs the add folder request and decodes the response.
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
}
