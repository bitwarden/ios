import XCTest

@testable import Networking

class HTTPResponseTests: XCTestCase {
    /// The initializer sets the item's properties.
    func testInit() {
        let subject = HTTPResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            headers: [:],
            body: Data(),
            requestID: UUID()
        )

        XCTAssertEqual(subject.body, Data())
        XCTAssertEqual(subject.headers, [:])
        XCTAssertEqual(subject.statusCode, 200)
        XCTAssertEqual(subject.url, URL(string: "https://example.com")!)
    }

    /// The initializer sets the item's properties with a `HTTPURLResponse`.
    func testInitResponse() throws {
        let subject = try HTTPResponse(
            data: "response body".data(using: .utf8)!,
            response: XCTUnwrap(HTTPURLResponse(
                url: URL(string: "https://example.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )),
            request: .default
        )

        XCTAssertEqual(
            try String(data: XCTUnwrap(subject.body), encoding: .utf8),
            "response body"
        )
        XCTAssertEqual(subject.headers, ["Content-Type": "application/json"])
        XCTAssertEqual(subject.statusCode, 200)
        XCTAssertEqual(subject.url, URL(string: "https://example.com")!)
    }

    /// Initializing an `HTTPResponse` with an `URLResponse` vs a `HTTPURLResponse` throws an error.
    func testInitWithURLResponseThrowsError() {
        let urlResponse = URLResponse(
            url: URL(string: "https://example.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )

        XCTAssertThrowsError(
            try HTTPResponse(
                data: Data(),
                response: urlResponse,
                request: .default
            ),
            "Expected a HTTPResponseError.invalidResponse error to be thrown"
        ) { error in
            XCTAssertTrue(error is HTTPResponseError)
            XCTAssertEqual(
                error as? HTTPResponseError,
                HTTPResponseError.invalidResponse(urlResponse)
            )
        }
    }
}
