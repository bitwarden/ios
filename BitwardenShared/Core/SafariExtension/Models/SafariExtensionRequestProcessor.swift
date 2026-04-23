// MARK: - SafariExtensionRequestProcessor

import BitwardenKit

public struct SafariExtensionRequestProcessor {
    private let matchedLoginResolver: (any SafariExtensionMatchedLoginResolving)?
    private let passwordGenerator: (PasswordGenerationOptions?) -> String

    public init() {
        matchedLoginResolver = nil
        passwordGenerator = { _ in "generated-password" }
    }

    @MainActor
    public static func liveForAppExtension(errorReporter: ErrorReporter) -> Self {
        live(services: ServiceContainer(appContext: .appExtension, errorReporter: errorReporter))
    }

    @MainActor
    static func live(services: ServiceContainer) -> Self {
        let matchedLoginResolver = SafariExtensionMatchedLoginResolver(
            cipherMatchingHelperFactory: DefaultCipherMatchingHelperFactory(
                settingsService: services.settingsService,
                stateService: services.stateService,
            ),
            ciphersClientWrapperService: DefaultCiphersClientWrapperService(
                clientService: services.clientService,
                errorReporter: services.errorReporter,
            ),
            cipherService: services.cipherService,
            stateService: services.stateService,
        )

        return Self(matchedLoginResolver: matchedLoginResolver)
    }

    init(
        matchedLoginResolver: (any SafariExtensionMatchedLoginResolving)? = nil,
        passwordGenerator: @escaping (PasswordGenerationOptions?) -> String = { _ in "generated-password" }
    ) {
        self.matchedLoginResolver = matchedLoginResolver
        self.passwordGenerator = passwordGenerator
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
            return try? SafariExtensionResponse.generatedPassword(passwordGenerator(request.passwordOptions), for: request)
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
            return "Save this login to Bitwarden."
        case .updateExistingLogin:
            return "Update the existing Bitwarden login with these changes."
        case .updatePassword:
            return "Update the password for this Bitwarden login."
        case .generatePassword:
            return nil
        }
    }
}
