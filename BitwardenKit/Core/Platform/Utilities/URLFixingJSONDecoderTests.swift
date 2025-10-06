import XCTest

@testable import BitwardenKit

// MARK: - URLFixingJSONDecoderTests

class URLFixingJSONDecoderTests: BitwardenTestCase {
    // MARK: Types

    private struct JSONContainerBody: Codable, Equatable {
        let urls: [URL]
        let someUrls: [URL]
    }

    private struct JSONBody: Codable, Equatable {
        let id: String
        let container: JSONContainerBody
    }

    // MARK: Properties

    var subject: URLFixingJSONDecoder!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = URLFixingJSONDecoder(urlArrayPropertyNames: ["urls"])
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `decode` using this JSON decoder fixes IP address URLs with port and decodes
    /// them correctly
    func test_decode_withValidJSON_decodesSuccessfully() throws {
        let toDecode =
            """
            {
                "id": "1",
                "container": {
                    "urls": [
                        "192.168.1.100:8080",
                        "192.168.1.100",
                        "10.0.0.2:4000/example",
                        "api.example.com/v1/endpoint",
                        "https://secure.example.com/api/v2"
                    ],
                    "someUrls": []
                }
            }   
            """

        let result = try subject.decode(JSONBody.self, from: Data(toDecode.utf8))
        XCTAssertEqual(
            result.container.urls.map(\.absoluteString),
            [
                "http://192.168.1.100:8080",
                "192.168.1.100",
                "http://10.0.0.2:4000/example",
                "api.example.com/v1/endpoint",
                "https://secure.example.com/api/v2",
            ],
        )
    }

    /// `decode` using this JSON decoder doesn't fix IP address URLs with port and throws when decoding
    /// a URL array property not configured in the decoder initializer.
    func test_decode_throwsWhenJSONHasURLsInPropertyNotIncludedInTheDecoderConfig() throws {
        let toDecode =
            """
            {
                "id": "1",
                "container": {
                    "urls": [],
                    "someUrls": [
                        "192.168.1.100:8080",
                        "192.168.1.100",
                        "10.0.0.2:4000/example",
                        "api.example.com/v1/endpoint",
                        "https://secure.example.com/api/v2"
                    ]
                }
            }   
            """

        XCTAssertThrowsError(try subject.decode(JSONBody.self, from: Data(toDecode.utf8)))
    }
}
