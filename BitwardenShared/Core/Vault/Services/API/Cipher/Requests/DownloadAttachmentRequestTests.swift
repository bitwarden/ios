import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class DownloadAttachmentRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DownloadAttachmentRequest!

    // MARK: Set Up & Tear Down

    override func setUp() {
        super.setUp()
        subject = DownloadAttachmentRequest(attachmentId: "1", cipherId: "2")
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
        XCTAssertEqual(subject.method, .get)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/ciphers/2/attachment/1")
    }
}
