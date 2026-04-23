import XCTest

@testable import BitwardenShared

class SafariExtensionBridgeCodecTests: BitwardenTestCase {
    func test_decodeRequestFromLegacyWrappedDictionary_parsesBridgeEnvelope() throws {
        let message: [String: Any] = [
            "message": [
                "id": "req-legacy",
                "request": [
                    "kind": "setup",
                ],
            ],
        ]

        let subject = try XCTUnwrap(SafariExtensionBridgeCodec.decodeRequest(from: message["message"]))

        XCTAssertEqual(subject.id, "req-legacy")
        XCTAssertEqual(subject.request, SafariExtensionRequest(kind: .setup))
    }

    func test_decodeRequestFromJSONString_parsesBridgeEnvelope() throws {
        let message = """
        {
          "id": "req-1",
          "request": {
            "kind": "generatePassword"
          }
        }
        """

        let subject = try XCTUnwrap(SafariExtensionBridgeCodec.decodeRequest(from: message))

        XCTAssertEqual(subject.id, "req-1")
        XCTAssertEqual(subject.request, SafariExtensionRequest(kind: .generatePassword))
    }

    func test_decodeRequestFromDictionary_parsesBridgeEnvelope() throws {
        let message: [String: Any] = [
            "id": "req-2",
            "request": [
                "kind": "setup",
            ],
        ]

        let subject = try XCTUnwrap(SafariExtensionBridgeCodec.decodeRequest(from: message))

        XCTAssertEqual(subject.id, "req-2")
        XCTAssertEqual(subject.request, SafariExtensionRequest(kind: .setup))
    }

    func test_encodeResponse_returnsJSONStringEnvelope() throws {
        let response = try SafariExtensionResponse.generatedPassword(
            "generated-secret",
            for: SafariExtensionRequest(kind: .generatePassword),
        )

        let encoded = try SafariExtensionBridgeCodec.encodeResponse(
            requestID: "req-1",
            response: response,
        )
        let decoded = try JSONDecoder().decode(SafariExtensionBridgeResponse.self, from: XCTUnwrap(encoded.data(using: .utf8)))

        XCTAssertEqual(decoded.id, "req-1")
        XCTAssertEqual(decoded.response.generatedPassword, "generated-secret")
        XCTAssertNil(decoded.errorMessage)
    }
}
