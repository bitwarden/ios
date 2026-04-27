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

    func test_decodeRequestFromDictionary_withRequestContext_parsesBridgeEnvelope() throws {
        let message: [String: Any] = [
            "id": "req-3",
            "request": [
                "kind": "saveLogin",
                "username": "user@example.com",
                "password": "secret",
                "requestContext": [
                    "trigger": "actionPanelPrimary",
                    "submissionAction": "saveNewLogin",
                ],
            ],
        ]

        let subject = try XCTUnwrap(SafariExtensionBridgeCodec.decodeRequest(from: message))

        XCTAssertEqual(subject.id, "req-3")
        XCTAssertEqual(subject.request.kind, .saveLogin)
        XCTAssertEqual(subject.request.requestContext?.trigger, .actionPanelPrimary)
        XCTAssertEqual(subject.request.requestContext?.submissionAction, .saveNewLogin)
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
        XCTAssertEqual(decoded.response?.generatedPassword, "generated-secret")
        XCTAssertNil(decoded.response?.followUpType)
        XCTAssertNil(decoded.errorMessage)
    }

    func test_encodeResponse_withFollowUpType_roundTrips() throws {
        let request = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/login",
            username: "user@example.com"
        )
        let followUpRequest = SafariExtensionRequest(
            kind: .saveLogin,
            password: "secret",
            urlString: "https://example.com/register",
            username: "user@example.com"
        )
        let response = SafariExtensionResponse(
            request: request,
            suggestionAction: .saveLogin,
            submissionAction: .saveNewLogin,
            matchedLogin: nil,
            fillScriptJSON: nil,
            generatedPassword: nil,
            userMessage: "Save this generated password to Bitwarden.",
            followUpType: .generatedPassword,
            followUpRequest: followUpRequest,
            followUpSubmissionAction: .saveNewLogin,
        )

        let encoded = try SafariExtensionBridgeCodec.encodeResponse(
            requestID: "req-followup",
            response: response,
        )
        let decoded = try JSONDecoder().decode(SafariExtensionBridgeResponse.self, from: XCTUnwrap(encoded.data(using: .utf8)))

        XCTAssertEqual(decoded.id, "req-followup")
        XCTAssertEqual(decoded.response?.followUpType, .generatedPassword)
        XCTAssertEqual(decoded.response?.followUpRequest?.urlString, "https://example.com/register")
        XCTAssertEqual(decoded.response?.followUpSubmissionAction, .saveNewLogin)
        XCTAssertEqual(decoded.response?.submissionAction, .saveNewLogin)
    }

    func test_encodeErrorResponse_returnsErrorOnlyJSONStringEnvelope() throws {
        let encoded = try SafariExtensionBridgeCodec.encodeErrorResponse(
            requestID: "req-error",
            errorMessage: "Invalid native request payload."
        )
        let decoded = try JSONDecoder().decode(SafariExtensionBridgeResponse.self, from: XCTUnwrap(encoded.data(using: .utf8)))

        XCTAssertEqual(decoded.id, "req-error")
        XCTAssertNil(decoded.response)
        XCTAssertEqual(decoded.errorMessage, "Invalid native request payload.")
    }
}
