import TestHelpers
import XCTest

@testable import BitwardenShared

@MainActor
class SafariWebExtensionHandlerTests: BitwardenTestCase {
    func test_makeResponseItem_withInvalidPayload_returnsInvalidRequestErrorEnvelope() async throws {
        let subject = SafariWebExtensionHandler(
            responseProvider: { _ in
                XCTFail("responseProvider should not be called for invalid payloads")
                return nil
            },
            bridgeMessageUserInfoKeyProvider: { SafariWebExtensionBridge.legacyMessageUserInfoKey }
        )

        let maybeItem = await subject.makeResponseItem(from: [:])
        let item = try XCTUnwrap(maybeItem)
        let userInfo = try XCTUnwrap(item.userInfo)
        let message = try XCTUnwrap(userInfo[SafariWebExtensionBridge.legacyMessageUserInfoKey] as? String)
        let decoded = try JSONDecoder().decode(
            SafariExtensionBridgeResponse.self,
            from: XCTUnwrap(message.data(using: String.Encoding.utf8))
        )

        XCTAssertEqual(decoded.id, "invalid-request")
        XCTAssertNil(decoded.response)
        XCTAssertEqual(decoded.errorMessage, "Invalid native request payload.")
    }

    func test_makeResponseItem_withValidPayload_usesInjectedResponseProvider() async throws {
        var capturedRequest: SafariExtensionRequest?
        let subject = SafariWebExtensionHandler(
            responseProvider: { request in
                capturedRequest = request
                return SafariExtensionResponse(
                    request: request,
                    suggestionAction: .none,
                    submissionAction: .none,
                    matchedLogin: nil,
                    fillScriptJSON: nil,
                    generatedPassword: nil,
                    userMessage: "Handled in tests."
                )
            },
            bridgeMessageUserInfoKeyProvider: { SafariWebExtensionBridge.legacyMessageUserInfoKey }
        )

        let maybeItem = await subject.makeResponseItem(from: [
            SafariWebExtensionBridge.legacyMessageUserInfoKey: """
            {
              \"id\": \"req-handler\",
              \"request\": {
                \"kind\": \"setup\",
                \"urlString\": \"https://example.com/setup\"
              }
            }
            """
        ])
        let item = try XCTUnwrap(maybeItem)
        let userInfo = try XCTUnwrap(item.userInfo)
        let message = try XCTUnwrap(userInfo[SafariWebExtensionBridge.legacyMessageUserInfoKey] as? String)
        let decoded = try JSONDecoder().decode(
            SafariExtensionBridgeResponse.self,
            from: XCTUnwrap(message.data(using: String.Encoding.utf8))
        )

        XCTAssertEqual(capturedRequest, SafariExtensionRequest(kind: .setup, urlString: "https://example.com/setup"))
        XCTAssertEqual(decoded.id, "req-handler")
        XCTAssertEqual(decoded.response?.userMessage, "Handled in tests.")
        XCTAssertNil(decoded.errorMessage)
    }

    func test_makeResponseItem_whenResponseProviderReturnsNil_returnsProcessingErrorEnvelope() async throws {
        let subject = SafariWebExtensionHandler(
            responseProvider: { _ in nil },
            bridgeMessageUserInfoKeyProvider: { SafariWebExtensionBridge.legacyMessageUserInfoKey }
        )

        let maybeItem = await subject.makeResponseItem(from: [
            SafariWebExtensionBridge.legacyMessageUserInfoKey: """
            {
              \"id\": \"req-processing-error\",
              \"request\": {
                \"kind\": \"setup\"
              }
            }
            """
        ])
        let item = try XCTUnwrap(maybeItem)
        let userInfo = try XCTUnwrap(item.userInfo)
        let message = try XCTUnwrap(userInfo[SafariWebExtensionBridge.legacyMessageUserInfoKey] as? String)
        let decoded = try JSONDecoder().decode(
            SafariExtensionBridgeResponse.self,
            from: XCTUnwrap(message.data(using: String.Encoding.utf8))
        )

        XCTAssertEqual(decoded.id, "req-processing-error")
        XCTAssertNil(decoded.response)
        XCTAssertEqual(decoded.errorMessage, "Couldn’t process Safari extension request.")
    }
}
