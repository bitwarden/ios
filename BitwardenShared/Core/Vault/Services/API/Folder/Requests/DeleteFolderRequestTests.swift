import XCTest

@testable import BitwardenShared

class DeleteFolderRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DeleteFolderRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DeleteFolderRequest(id: "123456789")
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .delete)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/folders/123456789")
    }
}
