// MARK: - SafariExtensionRequestProcessor

import BitwardenKit
import BitwardenSdk

public struct SafariExtensionRequestProcessor {
    private let matchedLoginResolver: (any SafariExtensionMatchedLoginResolving)?
    private let credentialStore: (any SafariExtensionCredentialStoring)?
    private let passwordGenerator: (PasswordGenerationOptions?) -> String
    private let generatedPasswordProducer: ((PasswordGenerationOptions?) async -> String?)?

    public init() {
        matchedLoginResolver = nil
        credentialStore = nil
        passwordGenerator = { _ in "generated-password" }
        generatedPasswordProducer = nil
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

        return Self(
            matchedLoginResolver: matchedLoginResolver,
            credentialStore: credentialStore,
            generatedPasswordProducer: { options in
                try? await Self.generatePassword(using: services.generatorRepository, options: options)
            }
        )
    }

    init(
        matchedLoginResolver: (any SafariExtensionMatchedLoginResolving)? = nil,
        credentialStore: (any SafariExtensionCredentialStoring)? = nil,
        passwordGenerator: @escaping (PasswordGenerationOptions?) -> String = { _ in "generated-password" },
        generatedPasswordProducer: ((PasswordGenerationOptions?) async -> String?)? = nil
    ) {
        self.matchedLoginResolver = matchedLoginResolver
        self.credentialStore = credentialStore
        self.passwordGenerator = passwordGenerator
        self.generatedPasswordProducer = generatedPasswordProducer
    }

    public func makeResponse(for request: SafariExtensionRequest) -> SafariExtensionResponse? {
        makeResponse(for: request, matchedLogin: nil)
    }

    public func makeAsyncResponse(for request: SafariExtensionRequest) async -> SafariExtensionResponse? {
        await makeResponse(for: request)
    }

    func makeResponse(for request: SafariExtensionRequest) async -> SafariExtensionResponse? {
        let matchedLogin = try? await matchedLoginResolver?.resolveMatchedLogin(for: request)

        if request.kind == .generatePassword {
            if let generatedPassword = await makeGeneratedPassword(for: request) {
                let followUpRequest = makeGeneratedPasswordFollowUpRequest(
                    for: request,
                    generatedPassword: generatedPassword
                )
                let followUpSubmissionAction = makeGeneratedPasswordFollowUpSubmissionAction(
                    for: followUpRequest,
                    matchedLogin: matchedLogin ?? nil
                )
                return try? SafariExtensionResponse.generatedPassword(
                    generatedPassword,
                    for: request,
                    matchedLogin: matchedLogin ?? nil,
                    followUpType: followUpSubmissionAction == nil ? nil : .generatedPassword,
                    followUpRequest: followUpRequest,
                    followUpSubmissionAction: followUpSubmissionAction,
                )
            }

            return SafariExtensionResponse(
                request: request,
                suggestionAction: SafariExtensionSuggestionAction.from(request),
                submissionAction: .none,
                matchedLogin: nil,
                fillScriptJSON: nil,
                generatedPassword: nil,
                userMessage: "Couldn’t generate a password in Bitwarden.",
            )
        }

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
            let followUpRequest = makeGeneratedPasswordFollowUpRequest(
                for: request,
                generatedPassword: passwordGenerator(request.passwordOptions)
            )
            let followUpSubmissionAction = makeGeneratedPasswordFollowUpSubmissionAction(
                for: followUpRequest,
                matchedLogin: nil
            )
            return try? SafariExtensionResponse.generatedPassword(
                passwordGenerator(request.passwordOptions),
                for: request,
                followUpType: followUpSubmissionAction == nil ? nil : .generatedPassword,
                followUpRequest: followUpRequest,
                followUpSubmissionAction: followUpSubmissionAction,
            )
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

    private func makeGeneratedPassword(for request: SafariExtensionRequest) async -> String? {
        if let generatedPasswordProducer {
            return await generatedPasswordProducer(request.passwordOptions)
        }

        return passwordGenerator(request.passwordOptions)
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

    private static func generatePassword(
        using generatorRepository: GeneratorRepository,
        options: PasswordGenerationOptions?
    ) async throws -> String {
        let resolvedOptions = try await generatorOptions(using: generatorRepository, options: options)

        switch resolvedOptions.type ?? .password {
        case .passphrase:
            return try await generatorRepository.generatePassphrase(
                settings: makePassphraseGeneratorRequest(from: resolvedOptions)
            )
        case .password:
            return try await generatorRepository.generatePassword(
                settings: makePasswordGeneratorRequest(from: resolvedOptions)
            )
        }
    }

    private static func generatorOptions(
        using generatorRepository: GeneratorRepository,
        options: PasswordGenerationOptions?
    ) async throws -> PasswordGenerationOptions {
        if let options {
            return options
        }

        return try await generatorRepository.getPasswordGenerationOptions()
    }

    private static func makePassphraseGeneratorRequest(from options: PasswordGenerationOptions) -> PassphraseGeneratorRequest {
        PassphraseGeneratorRequest(
            numWords: clampedUInt8(options.numWords ?? 3),
            wordSeparator: options.wordSeparator ?? "-",
            capitalize: options.capitalize ?? false,
            includeNumber: options.includeNumber ?? false
        )
    }

    private static func makePasswordGeneratorRequest(from options: PasswordGenerationOptions) -> PasswordGeneratorRequest {
        var lowercase = options.lowercase ?? true
        var uppercase = options.uppercase ?? true
        var numbers = options.number ?? true
        var special = options.special ?? true

        if !lowercase, !uppercase, !numbers, !special {
            lowercase = true
        }

        return PasswordGeneratorRequest(
            lowercase: lowercase,
            uppercase: uppercase,
            numbers: numbers,
            special: special,
            length: clampedUInt8(options.length ?? 14),
            avoidAmbiguous: !(options.allowAmbiguousChar ?? true),
            minLowercase: options.minLowercase.map(clampedUInt8),
            minUppercase: options.minUppercase.map(clampedUInt8),
            minNumber: options.minNumber.map(clampedUInt8),
            minSpecial: options.minSpecial.map(clampedUInt8)
        )
    }

    private static func clampedUInt8(_ value: Int) -> UInt8 {
        UInt8(max(1, min(value, Int(UInt8.max))))
    }
}

private extension SafariExtensionRequestProcessor {
    func makeGeneratedPasswordFollowUpRequest(
        for request: SafariExtensionRequest,
        generatedPassword: String
    ) -> SafariExtensionRequest? {
        guard let pageDetails = request.pageDetails else {
            return nil
        }

        let passwordFields = pageDetails.fields.filter { $0.type == "password" && $0.viewable }
        let roles = passwordFields.map(passwordFieldRole)
        let hasCurrentPassword = roles.contains(.current)
        let hasNewPassword = roles.contains(.new)
        let hasConfirmPassword = roles.contains(.confirm)

        if hasCurrentPassword && (hasNewPassword || hasConfirmPassword) {
            return SafariExtensionRequest(
                kind: .changePassword,
                oldPassword: currentPasswordValue(from: pageDetails),
                password: generatedPassword,
                urlString: request.urlString
            )
        }

        if hasNewPassword || hasConfirmPassword {
            if preferredUsername(from: pageDetails) == nil, isGeneratedPasswordChangePasswordSurface(pageDetails) {
                return SafariExtensionRequest(
                    kind: .changePassword,
                    password: generatedPassword,
                    urlString: request.urlString
                )
            }

            return SafariExtensionRequest(
                kind: .saveLogin,
                password: generatedPassword,
                urlString: request.urlString,
                username: preferredUsername(from: pageDetails)
            )
        }

        return nil
    }

    func makeGeneratedPasswordFollowUpSubmissionAction(
        for followUpRequest: SafariExtensionRequest?,
        matchedLogin: SafariExtensionMatchedLogin?
    ) -> SafariExtensionSubmissionAction? {
        guard let followUpRequest else {
            return nil
        }

        let action = SafariExtensionSubmissionAction.classify(followUpRequest, matchedLogin: matchedLogin)
        if action != .none {
            return action
        }

        switch followUpRequest.kind {
        case .changePassword:
            return .updatePassword
        case .saveLogin:
            return followUpRequest.username == nil ? nil : .saveNewLogin
        default:
            return nil
        }
    }

    func currentPasswordValue(from pageDetails: PageDetails?) -> String? {
        guard let pageDetails else {
            return nil
        }

        let currentPasswordField = pageDetails.fields.first { passwordFieldRole($0) == .current }
        return normalizedFieldValue(currentPasswordField)
    }

    func preferredUsername(from pageDetails: PageDetails?) -> String? {
        guard let pageDetails else {
            return nil
        }

        let fields = pageDetails.fields
        let preferredField = fields.first { $0.type == "email" && $0.viewable }
            ?? fields.first { $0.type == "text" && $0.viewable }
            ?? fields.first { $0.type == "tel" && $0.viewable }
            ?? fields.first { $0.type == "email" }

        return normalizedFieldValue(preferredField)
    }

    func normalizedFieldValue(_ field: PageDetails.Field?) -> String? {
        guard let value = field?.value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    func isGeneratedPasswordChangePasswordSurface(_ pageDetails: PageDetails) -> Bool {
        let text = generatedPasswordSurfaceText(pageDetails)
        return text.contains(where: isChangePasswordSurfaceText)
    }

    func generatedPasswordSurfaceText(_ pageDetails: PageDetails) -> [String] {
        var values: [String] = [pageDetails.title]
        values.append(contentsOf: pageDetails.forms.values.flatMap { [$0.htmlId, $0.htmlName, $0.htmlAction] })
        values.append(contentsOf: pageDetails.fields.flatMap {
            [
                $0.form,
                $0.htmlId,
                $0.htmlName,
                $0.labelLeft,
                $0.labelRight,
                $0.labelTag,
                $0.placeholder,
            ]
        }.compactMap { $0 })
        return values
    }

    func isChangePasswordSurfaceText(_ text: String) -> Bool {
        let tokens = ["change password", "update password", "reset password", "new password", "confirm new password"]
        return tokens.contains { text.localizedCaseInsensitiveContains($0) }
    }

    func passwordFieldRole(_ field: PageDetails.Field) -> PasswordFieldRole {
        let source = [field.htmlId, field.htmlName, field.labelTag, field.labelLeft, field.placeholder]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        if source.contains("current") || source.contains("old") {
            return .current
        }
        if source.contains("confirm") || source.contains("verification") || source.contains("verify")
            || source.contains("repeat") || source.contains("again") {
            return .confirm
        }
        if source.contains("new") || source.contains("create") || source.contains("choose") || source.contains("set") {
            return .new
        }
        return .unknown
    }

    enum PasswordFieldRole {
        case current
        case new
        case confirm
        case unknown
    }
}
