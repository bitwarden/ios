import BitwardenShared
import Foundation

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let inputItems = context.inputItems as? [NSExtensionItem] ?? []
        let responseItems = inputItems.compactMap { item in
            makeResponseItem(from: item.userInfo as? [String: Any] ?? [:])
        }
        context.completeRequest(returningItems: responseItems, completionHandler: nil)
    }

    func makeResponseItem(from userInfo: [String: Any]) -> NSExtensionItem? {
        guard let bridgeRequest = SafariWebExtensionBridge.decodeRequest(from: userInfo),
              let response = makeResponse(for: bridgeRequest.request) else {
            return nil
        }

        return try? SafariWebExtensionBridge.makeResponseItem(
            for: bridgeRequest,
            response: response,
        )
    }

    private func makeResponse(for request: SafariExtensionRequest) -> SafariExtensionResponse? {
        switch request.kind {
        case .generatePassword:
            return try? SafariExtensionResponse.generatedPassword("generated-password", for: request)
        case .setup:
            return SafariExtensionResponse(
                request: request,
                suggestionAction: .none,
                submissionAction: .none,
                matchedLogin: nil,
                fillScriptJSON: nil,
                generatedPassword: nil,
                userMessage: "Safari Web Extension setup",
            )
        case .fill, .saveLogin, .changePassword:
            let suggestionAction = SafariExtensionSuggestionAction.from(request)
            let submissionAction = SafariExtensionSubmissionAction.classify(request, matchedLogin: nil)
            return SafariExtensionResponse(
                request: request,
                suggestionAction: suggestionAction,
                submissionAction: submissionAction,
                matchedLogin: nil,
                fillScriptJSON: nil,
                generatedPassword: nil,
                userMessage: submissionAction == .none ? nil : suggestionAction.rawValue,
            )
        }
    }
}
