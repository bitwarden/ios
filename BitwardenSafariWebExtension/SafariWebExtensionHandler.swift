import BitwardenKit
import BitwardenShared
import Foundation
import SafariServices

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    typealias ResponseProvider = @MainActor (SafariExtensionRequest) async -> SafariExtensionResponse?

    private let responseProvider: ResponseProvider
    private let bridgeMessageUserInfoKeyProvider: () -> String

    @MainActor
    override convenience init() {
        self.init(
            responseProvider: { request in
                let requestProcessor = SafariExtensionRequestProcessor.liveForAppExtension(
                    errorReporter: OSLogErrorReporter(),
                )
                return await requestProcessor.makeAsyncResponse(for: request)
            }
        )
    }

    @MainActor
    init(
        responseProvider: @escaping ResponseProvider,
        bridgeMessageUserInfoKeyProvider: @escaping () -> String = {
            if #available(iOS 15.0, macOS 11.0, *) {
                return SFExtensionMessageKey
            }
            return SafariWebExtensionBridge.legacyMessageUserInfoKey
        }
    ) {
        self.responseProvider = responseProvider
        self.bridgeMessageUserInfoKeyProvider = bridgeMessageUserInfoKeyProvider
        super.init()
    }

    func beginRequest(with context: NSExtensionContext) {
        Task { @MainActor in
            let inputItems = context.inputItems as? [NSExtensionItem] ?? []
            let responseItems = await inputItems.asyncCompactMap { item in
                await makeResponseItem(from: item.userInfo as? [String: Any] ?? [:])
            }
            context.completeRequest(returningItems: responseItems, completionHandler: nil)
        }
    }

    @MainActor
    func makeResponseItem(from userInfo: [String: Any]) async -> NSExtensionItem? {
        let rawMessage = userInfo[bridgeMessageUserInfoKey] ?? userInfo[SafariWebExtensionBridge.legacyMessageUserInfoKey]
        NSLog("BW Safari native raw message type: %@", String(describing: type(of: rawMessage as Any)))
        let fallbackRequestID = (rawMessage as? [String: Any]).flatMap { $0["id"] as? String } ?? "invalid-request"

        guard let bridgeRequest = SafariExtensionBridgeCodec.decodeRequest(from: rawMessage) else {
            NSLog("BW Safari native decode failed")
            return makeBridgeItem(from: try? SafariExtensionBridgeCodec.encodeErrorResponse(
                requestID: fallbackRequestID,
                errorMessage: "Invalid native request payload.",
            ))
        }

        guard let response = await responseProvider(bridgeRequest.request) else {
            NSLog("BW Safari native response nil for kind: %@", bridgeRequest.request.kind.rawValue)
            return makeBridgeItem(from: try? SafariExtensionBridgeCodec.encodeErrorResponse(
                requestID: bridgeRequest.id,
                errorMessage: "Couldn’t process Safari extension request.",
            ))
        }
        NSLog(
            "BW Safari native response kind=%@ canFinalize=%@ hasGenerated=%@",
            bridgeRequest.request.kind.rawValue,
            response.canFinalizeWithScript ? "true" : "false",
            response.hasGeneratedPassword ? "true" : "false"
        )

        return makeBridgeItem(from: try? SafariExtensionBridgeCodec.encodeResponse(
            requestID: bridgeRequest.id,
            response: response,
        ))
    }

    private func makeBridgeItem(from message: String?) -> NSExtensionItem? {
        guard let message else {
            return nil
        }

        let item = NSExtensionItem()
        item.userInfo = [bridgeMessageUserInfoKey: message]
        return item
    }

    private var bridgeMessageUserInfoKey: String {
        bridgeMessageUserInfoKeyProvider()
    }
}

private extension Array {
    func asyncCompactMap<T>(_ transform: (Element) async -> T?) async -> [T] {
        var results: [T] = []
        for element in self {
            if let value = await transform(element) {
                results.append(value)
            }
        }
        return results
    }
}
