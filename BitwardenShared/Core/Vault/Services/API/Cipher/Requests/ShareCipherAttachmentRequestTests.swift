import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class ShareCipherAttachmentRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: ShareCipherAttachmentRequest!

    override func setUp() {
        super.setUp()

        subject = try? ShareCipherAttachmentRequest(
            attachment: .fixture(id: "attachment-1"),
            attachmentData: Data("📜".utf8),
            cipherId: "1",
            date: Date(year: 2024, month: 6, day: 1),
            organizationId: "org-1"
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns the JSON encoded cipher.
    func test_body() throws {
        let bodyData = try XCTUnwrap(subject.body?.data)
        try assertInlineSnapshot(of: XCTUnwrap(String(data: bodyData, encoding: .utf8)), as: .lines) {
            """
            ----BWMobileFormBoundary1717200000000.0\r
            Content-Disposition: form-data; name="data"; filename=""\r
            Content-Type: application/octet-stream\r
            \r
            📜\r
            ----BWMobileFormBoundary1717200000000.0--\r

            """
        }
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/ciphers/1/attachment/attachment-1/share")
    }

    /// `query` returns the query items of the request.
    func test_query() {
        XCTAssertEqual(subject.query, [URLQueryItem(name: "organizationId", value: "org-1")])
    }
}
