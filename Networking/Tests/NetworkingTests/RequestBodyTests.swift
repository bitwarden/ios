import XCTest

@testable import Networking

class RequestBodyTests: XCTestCase {
    struct TestRequestBodyJSON: JSONRequestBody {
        static var encoder = JSONEncoder()

        let name = "john"
    }

    struct TestRequestBodyFormURLEncoded: FormURLEncodedRequestBody {
        let values: [URLQueryItem]
    }

    /// `JSONRequestBody` can encode the JSON request body and provide additional headers.
    func test_requestBody_json() throws {
        let subject = TestRequestBodyJSON()

        XCTAssertEqual(subject.additionalHeaders, ["Content-Type": "application/json"])

        let encodedData = try subject.encode()
        XCTAssertEqual(String(data: encodedData, encoding: .utf8), #"{"name":"john"}"#)
    }

    /// Test that `Data` conforms to `RequestBody` and can be used directly.
    func test_requestBody_data() throws {
        let data = try XCTUnwrap("💾".data(using: .utf8))

        let subject: RequestBody = data

        XCTAssertEqual(subject.additionalHeaders, [:])
        XCTAssertEqual(try subject.encode(), data)
    }

    /// `FormURLEncodedBody` can encode a list of key-value pairs for a form URL encoded body.
    func test_requestBody_formURLEncoded() throws {
        let subject = TestRequestBodyFormURLEncoded(values: [
            URLQueryItem(name: "foo", value: "bar"),
            URLQueryItem(name: "abc", value: "xyz"),
        ])

        XCTAssertEqual(subject.additionalHeaders, ["Content-Type": "application/x-www-form-urlencoded"])

        XCTAssertEqual(
            try String(data: subject.encode(), encoding: .utf8),
            "foo=bar&abc=xyz"
        )
    }

    /// `FormURLEncodedRequestBody` uses percent encoding to handle special characters.
    func test_requestBody_formURLEncoded_usesPercentEncoding() throws {
        let subject = TestRequestBodyFormURLEncoded(values: [
            URLQueryItem(name: "foo", value: "a b c"),
            URLQueryItem(name: "bar", value: "+=&"),
            URLQueryItem(name: "email", value: "test+1@example.com"),
        ])

        XCTAssertEqual(subject.additionalHeaders, ["Content-Type": "application/x-www-form-urlencoded"])

        XCTAssertEqual(
            try String(data: subject.encode(), encoding: .utf8),
            "foo=a%20b%20c&bar=%2B%3D%26&email=test%2B1%40example%2Ecom"
        )
    }
}
