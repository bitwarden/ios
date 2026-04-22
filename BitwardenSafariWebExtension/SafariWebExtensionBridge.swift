import BitwardenShared
import Foundation
import SafariServices

struct SafariWebExtensionBridgeRequest: Codable, Equatable {
    var id: String
    var request: SafariExtensionRequest
}

struct SafariWebExtensionBridgeResponse: Codable, Equatable {
    var id: String
    var response: SafariExtensionResponse
    var errorMessage: String?
}

enum SafariWebExtensionBridge {
    static let legacyMessageUserInfoKey = "message"

    static var messageUserInfoKey: String {
        if #available(iOS 15.0, macOS 11.0, *) {
            return SFExtensionMessageKey
        }
        return legacyMessageUserInfoKey
    }

    static func decodeRequest(from userInfo: [String: Any]) -> SafariWebExtensionBridgeRequest? {
        let rawMessage = userInfo[messageUserInfoKey] ?? userInfo[legacyMessageUserInfoKey]

        if let message = rawMessage as? String,
           let data = message.data(using: .utf8) {
            return try? JSONDecoder().decode(SafariWebExtensionBridgeRequest.self, from: data)
        }

        if let message = rawMessage as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: message) {
            return try? JSONDecoder().decode(SafariWebExtensionBridgeRequest.self, from: data)
        }

        return nil
    }

    static func makeResponseItem(
        for request: SafariWebExtensionBridgeRequest,
        response: SafariExtensionResponse,
        errorMessage: String? = nil,
    ) throws -> NSExtensionItem {
        let bridgeResponse = SafariWebExtensionBridgeResponse(
            id: request.id,
            response: response,
            errorMessage: errorMessage,
        )
        let data = try JSONEncoder().encode(bridgeResponse)
        guard let message = String(data: data, encoding: .utf8) else {
            throw CocoaError(.coderInvalidValue)
        }

        let item = NSExtensionItem()
        item.userInfo = [messageUserInfoKey: message]
        return item
    }
}
