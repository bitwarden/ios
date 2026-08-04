import TestHelpers
import XCTest

@testable import BitwardenShared

class SafariWebExtensionBridgeTests: BitwardenTestCase {
    func test_decodeRequest_fromLegacyMessageUserInfo_parsesBridgeEnvelope() throws {
        let subject = try XCTUnwrap(SafariWebExtensionBridge.decodeRequest(from: [
            SafariWebExtensionBridge.legacyMessageUserInfoKey: """
            {
              \"id\": \"req-bridge\",
              \"request\": {
                \"kind\": \"setup\"
              }
            }
            """
        ]))

        XCTAssertEqual(subject.id, "req-bridge")
        XCTAssertEqual(subject.request, SafariExtensionRequest(kind: .setup))
    }

    func test_makeResponseItem_encodesBridgeResponse_intoConfiguredMessageUserInfoKey() throws {
        let request = SafariWebExtensionBridgeRequest(
            id: "req-response",
            request: SafariExtensionRequest(kind: .setup)
        )
        let response = SafariExtensionResponse(
            request: request.request,
            suggestionAction: .none,
            submissionAction: .none,
            matchedLogin: nil,
            fillScriptJSON: nil,
            generatedPassword: nil,
            userMessage: "Open Bitwarden to finish Safari extension setup."
        )

        let item = try SafariWebExtensionBridge.makeResponseItem(
            for: request,
            response: response,
            errorMessage: "Setup is incomplete."
        )
        let message = try XCTUnwrap(item.userInfo?[SafariWebExtensionBridge.messageUserInfoKey] as? String)
        let decoded = try JSONDecoder().decode(
            SafariWebExtensionBridgeResponse.self,
            from: XCTUnwrap(message.data(using: String.Encoding.utf8))
        )

        XCTAssertEqual(decoded.id, "req-response")
        XCTAssertEqual(decoded.response.userMessage, "Open Bitwarden to finish Safari extension setup.")
        XCTAssertEqual(decoded.errorMessage, "Setup is incomplete.")
    }
}
