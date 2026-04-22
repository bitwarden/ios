// MARK: - SafariExtensionRequestProcessor

public struct SafariExtensionRequestProcessor {
    public init() {}

    public func makeResponse(for request: SafariExtensionRequest) -> SafariExtensionResponse? {
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
