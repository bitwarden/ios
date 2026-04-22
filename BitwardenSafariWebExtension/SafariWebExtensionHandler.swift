import BitwardenShared
import Foundation
import SafariServices

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let requestProcessor = SafariExtensionRequestProcessor()

    func beginRequest(with context: NSExtensionContext) {
        let inputItems = context.inputItems as? [NSExtensionItem] ?? []
        let responseItems = inputItems.compactMap { item in
            makeResponseItem(from: item.userInfo as? [String: Any] ?? [:])
        }
        context.completeRequest(returningItems: responseItems, completionHandler: nil)
    }

    func makeResponseItem(from userInfo: [String: Any]) -> NSExtensionItem? {
        let rawMessage = userInfo[bridgeMessageUserInfoKey] ?? userInfo[SafariWebExtensionBridge.legacyMessageUserInfoKey]
        guard let bridgeRequest = SafariExtensionBridgeCodec.decodeRequest(from: rawMessage),
              let response = requestProcessor.makeResponse(for: bridgeRequest.request) else {
            return nil
        }

        guard let message = try? SafariExtensionBridgeCodec.encodeResponse(
            requestID: bridgeRequest.id,
            response: response,
        ) else {
            return nil
        }

        let item = NSExtensionItem()
        item.userInfo = [bridgeMessageUserInfoKey: message]
        return item
    }

    private var bridgeMessageUserInfoKey: String {
        if #available(iOS 15.0, macOS 11.0, *) {
            return SFExtensionMessageKey
        }
        return SafariWebExtensionBridge.legacyMessageUserInfoKey
    }
}
