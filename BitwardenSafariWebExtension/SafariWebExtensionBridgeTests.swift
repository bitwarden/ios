import XCTest

@testable import BitwardenSafariWebExtension
@testable import BitwardenShared

class SafariWebExtensionBridgeTests: BitwardenTestCase {
    func test_decodeRequest_parsesBridgeEnvelope() throws {
        let bridgeJSON = """
        {
          "id": "req-1",
          "request": {
            "kind": "generatePassword"
          }
        }
        """
        let userInfo: [String: Any] = [
            SafariWebExtensionBridge.legacyMessageUserInfoKey: bridgeJSON,
        ]

        let subject = try XCTUnwrap(SafariWebExtensionBridge.decodeRequest(from: userInfo))

        XCTAssertEqual(subject.id, "req-1")
        XCTAssertEqual(subject.request, SafariExtensionRequest(kind: .generatePassword))
    }

    func test_makeResponseItem_wrapsBridgeResponseInExtensionItem() throws {
        let response = try SafariExtensionResponse.generatedPassword(
            "generated-secret",
            for: SafariExtensionRequest(kind: .generatePassword),
        )

        let item = try SafariWebExtensionBridge.makeResponseItem(
            for: SafariWebExtensionBridgeRequest(
                id: "req-1",
                request: SafariExtensionRequest(kind: .generatePassword),
            ),
            response: response,
        )

        let userInfo = try XCTUnwrap(item.userInfo as? [String: Any])
        let message = try XCTUnwrap(
            (userInfo[SafariWebExtensionBridge.messageUserInfoKey] ?? userInfo[SafariWebExtensionBridge.legacyMessageUserInfoKey]) as? String,
        )
        let bridgeResponse = try JSONDecoder().decode(
            SafariWebExtensionBridgeResponse.self,
            from: XCTUnwrap(message.data(using: .utf8)),
        )

        XCTAssertEqual(bridgeResponse.id, "req-1")
        XCTAssertEqual(bridgeResponse.response.generatedPassword, "generated-secret")
        XCTAssertNil(bridgeResponse.errorMessage)
    }
}
