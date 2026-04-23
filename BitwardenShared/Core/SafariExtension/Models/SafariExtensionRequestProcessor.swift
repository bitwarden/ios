// MARK: - SafariExtensionRequestProcessor

public struct SafariExtensionRequestProcessor {
    private let matchedLoginResolver: (any SafariExtensionMatchedLoginResolving)?

    public init() {
        matchedLoginResolver = nil
    }

    init(matchedLoginResolver: (any SafariExtensionMatchedLoginResolving)? = nil) {
        self.matchedLoginResolver = matchedLoginResolver
    }

    public func makeResponse(for request: SafariExtensionRequest) -> SafariExtensionResponse? {
        makeResponse(for: request, matchedLogin: nil)
    }

    func makeResponse(for request: SafariExtensionRequest) async -> SafariExtensionResponse? {
        let matchedLogin = try? await matchedLoginResolver?.resolveMatchedLogin(for: request)
        return makeResponse(for: request, matchedLogin: matchedLogin ?? nil)
    }

    private func makeResponse(
        for request: SafariExtensionRequest,
        matchedLogin: SafariExtensionMatchedLogin?,
    ) -> SafariExtensionResponse? {
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
        case .fill:
            guard let matchedLogin,
                  let username = matchedLogin.username,
                  let password = matchedLogin.password else {
                return SafariExtensionResponse(
                    request: request,
                    suggestionAction: SafariExtensionSuggestionAction.from(request),
                    submissionAction: SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin),
                    matchedLogin: matchedLogin,
                    fillScriptJSON: nil,
                    generatedPassword: nil,
                    userMessage: makeUserMessage(for: SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin)),
                )
            }

            return try? SafariExtensionResponse.fill(
                request: request,
                username: username,
                password: password,
                fields: [],
                matchedLogin: matchedLogin,
            )
        case .saveLogin, .changePassword:
            let suggestionAction = SafariExtensionSuggestionAction.from(request)
            let submissionAction = SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin)
            return SafariExtensionResponse(
                request: request,
                suggestionAction: suggestionAction,
                submissionAction: submissionAction,
                matchedLogin: matchedLogin,
                fillScriptJSON: nil,
                generatedPassword: nil,
                userMessage: makeUserMessage(for: submissionAction),
            )
        }
    }

    private func makeUserMessage(for submissionAction: SafariExtensionSubmissionAction) -> String? {
        switch submissionAction {
        case .none, .fill:
            return nil
        case .saveNewLogin:
            return "saveLogin"
        case .updateExistingLogin:
            return "updateExistingLogin"
        case .updatePassword:
            return "updatePassword"
        case .generatePassword:
            return nil
        }
    }
}
