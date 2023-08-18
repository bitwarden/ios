import XCTest

@testable import Networking

class RequestBodyTests: XCTestCase {
    struct TestRequestBodyJSON: JSONRequestBody {
        static var encoder = JSONEncoder()

        let name = "john"
    }

    /// `JSONRequestBody` can encode the JSON request body and provide additional headers.
    func testRequestBodyJSON() throws {
        let subject = TestRequestBodyJSON()

        XCTAssertEqual(subject.additionalHeaders, ["Content-Type": "application/json"])

        let encodedData = try subject.encode()
        XCTAssertEqual(String(data: encodedData, encoding: .utf8), #"{"name":"john"}"#)
    }

    /// Test that `Data` conforms to `RequestBody` and can be used directly.
    func testRequestBodyData() throws {
        let data = try XCTUnwrap("💾".data(using: .utf8))

        let subject: RequestBody = data

        XCTAssertEqual(subject.additionalHeaders, [:])
        XCTAssertEqual(try subject.encode(), data)
    }
}
