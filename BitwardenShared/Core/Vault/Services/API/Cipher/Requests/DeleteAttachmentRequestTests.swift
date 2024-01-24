import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class DeleteAttachmentRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DeleteAttachmentRequest!

    // MARK: Set Up & Tear Down

    override func setUp() {
        super.setUp()
        subject = DeleteAttachmentRequest(attachmentId: "456", cipherId: "123")
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `body` returns nil.
    func test_body() {
        XCTAssertNil(subject.body)
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .delete)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/ciphers/123/attachment/456")
    }
}
