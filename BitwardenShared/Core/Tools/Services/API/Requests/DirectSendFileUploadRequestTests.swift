import XCTest

@testable import BitwardenShared

// MARK: - DirectSendFileUploadRequestTests

class DirectSendFileUploadRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(data:fileName:fileId:sendId:)` initializes the properties correctly.
    func test_init() {
        let data = Data("example".utf8)
        let date = Date(year: 2024, month: 1, day: 19, hour: 9, minute: 41, second: 42)
        let subject = DirectSendFileUploadRequest(
            data: data,
            fileName: "file_name",
            fileId: "file_id",
            sendId: "send_id"
        )

        XCTAssertEqual(subject.fileId, "file_id")
        XCTAssertEqual(subject.sendId, "send_id")
    }
}
