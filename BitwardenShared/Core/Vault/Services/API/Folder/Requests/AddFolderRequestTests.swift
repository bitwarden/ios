import XCTest

@testable import BitwardenShared

class AddFolderRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: AddFolderRequest!

    override func setUp() {
        super.setUp()

        subject = AddFolderRequest(name: "Something Clever")
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns the JSON encoded cipher.
    func test_body() throws {
        XCTAssertEqual(subject.body, FolderRequestModel(name: "Something Clever"))
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/folders")
    }
}
