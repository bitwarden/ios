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
        let fallbackRequestID = (rawMessage as? [String: Any]).flatMap { $0["id"] as? String } ?? "invalid-request"

        guard let bridgeRequest = SafariExtensionBridgeCodec.decodeRequest(from: rawMessage) else {
            return makeBridgeItem(from: try? SafariExtensionBridgeCodec.encodeErrorResponse(
                requestID: fallbackRequestID,
                errorMessage: "Invalid native request payload.",
            ))
        }

        guard let response = await responseProvider(bridgeRequest.request) else {
            return makeBridgeItem(from: try? SafariExtensionBridgeCodec.encodeErrorResponse(
                requestID: bridgeRequest.id,
                errorMessage: "Couldn’t process Safari extension request.",
            ))
        }

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
