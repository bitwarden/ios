import XCTest

@testable import BitwardenSafariWebExtension
@testable import BitwardenShared

class SafariWebExtensionHandlerTests: BitwardenTestCase {
    func test_handleUserInfo_generatePassword_returnsBridgeResponse() throws {
        let bridgeJSON = """
        {
          "id": "req-1",
          "request": {
            "kind": "generatePassword"
          }
        }
        """
        let subject = SafariWebExtensionHandler()

        let item = try XCTUnwrap(subject.makeResponseItem(from: [
            SafariWebExtensionBridge.legacyMessageUserInfoKey: bridgeJSON,
        ]))

        let userInfo = try XCTUnwrap(item.userInfo as? [String: Any])
        let message = try XCTUnwrap(
            (userInfo[SafariWebExtensionBridge.messageUserInfoKey] ?? userInfo[SafariWebExtensionBridge.legacyMessageUserInfoKey]) as? String,
        )
        let bridgeResponse = try JSONDecoder().decode(
            SafariWebExtensionBridgeResponse.self,
            from: XCTUnwrap(message.data(using: .utf8)),
        )

        XCTAssertEqual(bridgeResponse.id, "req-1")
        XCTAssertEqual(bridgeResponse.response.generatedPassword, "generated-password")
        XCTAssertEqual(bridgeResponse.response.submissionAction, .generatePassword)
    }

    func test_handleUserInfo_invalidPayload_returnsNil() {
        let subject = SafariWebExtensionHandler()

        XCTAssertNil(subject.makeResponseItem(from: [:]))
    }
}
