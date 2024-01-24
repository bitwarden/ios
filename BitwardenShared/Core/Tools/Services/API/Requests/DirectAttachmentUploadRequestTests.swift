import XCTest

@testable import BitwardenShared

// MARK: - DirectAttachmentUploadRequestTests

class DirectAttachmentUploadRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(attachmentId:data:cipherId:fileName:)` initializes the properties correctly.
    func test_init() {
        let data = Data("example".utf8)
        let subject = DirectAttachmentUploadRequest(
            attachmentId: "10", data: data, cipherId: "11", fileName: "cheese.txt"
        )

        XCTAssertEqual(subject.attachmentId, "10")
        XCTAssertEqual(subject.cipherId, "11")
        XCTAssertEqual(subject.path, "/ciphers/11/attachment/10")
        XCTAssertEqual(subject.method, .post)
    }
}
