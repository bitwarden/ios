import XCTest

@testable import BitwardenShared

// MARK: - AzureFileUploadRequestTests

class AzureFileUploadRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(data:date:url:)` initializes the properties correctly.
    func test_init() {
        let data = Data("example".utf8)
        let date = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41, second: 42)
        let url = URL.example.appending(queryItems: [.init(name: "sv", value: "2023-11-04")])!
        let subject = AzureFileUploadRequest(
            data: data,
            date: date,
            url: url
        )

        XCTAssertEqual(
            subject.headers,
            [
                "x-ms-date": "Sun, 5 Nov 2023 09:41:42 GMT",
                "x-ms-version": "2023-11-04",
                "x-ms-blob-type": "BlockBlob",
                "Content-Length": "\(data.count)",
            ]
        )
        XCTAssertEqual(subject.url, url)
        XCTAssertEqual(subject.body, data)
    }
}
