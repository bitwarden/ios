// MARK: - SafariExtensionRequestProcessor

import BitwardenKit

public struct SafariExtensionRequestProcessor {
    private let matchedLoginResolver: (any SafariExtensionMatchedLoginResolving)?
    private let credentialStore: (any SafariExtensionCredentialStoring)?
    private let passwordGenerator: (PasswordGenerationOptions?) -> String

    public init() {
        matchedLoginResolver = nil
        credentialStore = nil
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
        let credentialStore = SafariExtensionCredentialStoreService(
            cipherService: services.cipherService,
            clientService: services.clientService,
        )

        return Self(matchedLoginResolver: matchedLoginResolver, credentialStore: credentialStore)
    }

    init(
        matchedLoginResolver: (any SafariExtensionMatchedLoginResolving)? = nil,
        credentialStore: (any SafariExtensionCredentialStoring)? = nil,
        passwordGenerator: @escaping (PasswordGenerationOptions?) -> String = { _ in "generated-password" }
    ) {
        self.matchedLoginResolver = matchedLoginResolver
        self.credentialStore = credentialStore
        self.passwordGenerator = passwordGenerator
    }

    public func makeResponse(for request: SafariExtensionRequest) -> SafariExtensionResponse? {
        makeResponse(for: request, matchedLogin: nil)
    }

    func makeResponse(for request: SafariExtensionRequest) async -> SafariExtensionResponse? {
        let matchedLogin = try? await matchedLoginResolver?.resolveMatchedLogin(for: request)

        if request.requestContext?.trigger == .actionPanelPrimary {
            let submissionAction = request.requestContext?.submissionAction
                ?? SafariExtensionSubmissionAction.classify(request, matchedLogin: matchedLogin ?? nil)
            if let persistedResponse = await makePersistedResponse(
                for: request,
                matchedLogin: matchedLogin ?? nil,
                submissionAction: submissionAction,
            ) {
                return persistedResponse
            }
        }

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
                    submissionAction: .none,
                    matchedLogin: matchedLogin,
                    fillScriptJSON: nil,
                    generatedPassword: nil,
                    userMessage: "No matching Bitwarden login found for this page.",
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

    private func makePersistedResponse(
        for request: SafariExtensionRequest,
        matchedLogin: SafariExtensionMatchedLogin?,
        submissionAction: SafariExtensionSubmissionAction,
    ) async -> SafariExtensionResponse? {
        guard let credentialStore,
              [.saveNewLogin, .updateExistingLogin, .updatePassword].contains(submissionAction) else {
            return nil
        }

        do {
            try await credentialStore.saveCredential(
                for: request,
                matchedLogin: matchedLogin,
                submissionAction: submissionAction,
            )
            return SafariExtensionResponse(
                request: request,
                suggestionAction: SafariExtensionSuggestionAction.from(request),
                submissionAction: submissionAction,
                matchedLogin: matchedLogin,
                fillScriptJSON: nil,
                generatedPassword: nil,
                userMessage: makePersistedUserMessage(for: submissionAction),
            )
        } catch {
            return SafariExtensionResponse(
                request: request,
                suggestionAction: SafariExtensionSuggestionAction.from(request),
                submissionAction: submissionAction,
                matchedLogin: matchedLogin,
                fillScriptJSON: nil,
                generatedPassword: nil,
                userMessage: makePersistenceFailureMessage(for: submissionAction),
            )
        }
    }

    private func makePersistedUserMessage(for submissionAction: SafariExtensionSubmissionAction) -> String? {
        switch submissionAction {
        case .saveNewLogin:
            return "Saved login to Bitwarden."
        case .updateExistingLogin:
            return "Updated the Bitwarden login."
        case .updatePassword:
            return "Updated the Bitwarden password."
        default:
            return nil
        }
    }

    private func makePersistenceFailureMessage(for submissionAction: SafariExtensionSubmissionAction) -> String? {
        switch submissionAction {
        case .saveNewLogin:
            return "Couldn’t save this login to Bitwarden."
        case .updateExistingLogin:
            return "Couldn’t update this Bitwarden login."
        case .updatePassword:
            return "Couldn’t update this Bitwarden password."
        default:
            return nil
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
