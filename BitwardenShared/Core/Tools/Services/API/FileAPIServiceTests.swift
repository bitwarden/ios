import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - FileAPIServiceTests

class FileAPIServiceTests: BitwardenTestCase {
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
        client = MockHTTPClient()
        subject = nil
    }

    // MARK: Tests

    /// `uploadCipherAttachment(attachmentId:cipherId:data:fileName:type:url:)` uploads the file directly.
    func test_uploadCipherAttachment_direct() async throws {
        client.result = .success(.success())
        let data = Data("example".utf8)
        try await subject.uploadCipherAttachment(
            attachmentId: "10",
            cipherId: "11",
            data: data,
            fileName: "cheese.txt",
            type: .direct,
            url: .example,
        )

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/ciphers/11/attachment/10")
        XCTAssertNotNil(request.body)
    }

    /// `uploadCipherAttachment(attachmentId:cipherId:data:fileName:type:url:)` uploads the file using Azure.
    func test_uploadCipherAttachment_azure() async throws {
        client.result = .success(.success())
        let data = Data("example".utf8)
        let url = URL.example.appending(queryItems: [.init(name: "sv", value: "version2")])!
        try await subject.uploadCipherAttachment(
            attachmentId: "10",
            cipherId: "11",
            data: data,
            fileName: "cheese.txt",
            type: .azure,
            url: url,
        )

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .put)
        XCTAssertEqual(request.url.absoluteString, "https://example.com?sv=version2")
        XCTAssertEqual(request.body, data)
        XCTAssertEqual(request.headers["x-ms-version"], "version2")
    }

    /// `uploadSendFile(data:type:fileId:fileName:sendId:url:)` uploads the file using Azure.
    func test_uploadSendFile_azure() async throws {
        client.result = .success(.success())
        let data = Data("example".utf8)
        let url = URL.example.appending(queryItems: [.init(name: "sv", value: "version2")])!
        try await subject.uploadSendFile(
            data: data,
            type: .azure,
            fileId: "file_id",
            fileName: "file_name",
            sendId: "send_id",
            url: url,
        )

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .put)
        XCTAssertEqual(request.url.absoluteString, "https://example.com?sv=version2")
        XCTAssertEqual(request.body, data)
        XCTAssertEqual(request.headers["x-ms-version"], "version2")
    }

    /// `uploadSendFile(data:type:fileId:fileName:sendId:url:)` uploads the file directly.
    func test_uploadSendFile_direct() async throws {
        client.result = .success(.success())
        let data = Data("example".utf8)
        try await subject.uploadSendFile(
            data: data,
            type: .direct,
            fileId: "file_id",
            fileName: "file_name",
            sendId: "send_id",
            url: .example,
        )

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/sends/send_id/file/file_id")
        XCTAssertNotNil(request.body)
    }
}
