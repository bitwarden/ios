import BitwardenKit
import BitwardenResources
import BitwardenSdk
import OSLog

/// The processor used to manage state and handle actions for the generator screen.
///
final class GeneratorProcessor: StateProcessor<GeneratorState, GeneratorAction, GeneratorEffect> {
    // swiftlint:disable:previous type_body_length

    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasGeneratorRepository
        & HasPasteboardService
        & HasPolicyService
        & HasReviewPromptService
        & HasStateService

    /// The behavior that should be taken after receiving a new action for generating a new value
    /// and persisting it.
    ///
    enum GenerateValueBehavior {
        /// A new value should be generated and saved to the user's password history based on the
        /// `shouldSave` associated value (saving the value only applies to generated passwords).
        case generateNewValue(shouldSave: Bool)

        /// The existing generated value should be saved without generating a new value. This is
        /// used to generate a new value as the length slider changes, but only save the last
        /// generated value when the slider ends editing.
        case saveExistingValue
    }

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<GeneratorRoute, Void>

    /// A flag set once the initial generator options have been loaded.
    private(set) var didLoadGeneratorOptions = false

    /// The key path of the currently focused text field.
    private var focusedKeyPath: KeyPath<GeneratorState, String>?

    /// Whether the slider is currently in editing mode.
    private var isEditingSlider = false

    /// The task used to generate a new value so it can be cancelled if needed.
    private var generateValueTask: Task<Void, Never>?

    /// The task used to load the generator options.
    private var loadGeneratorOptionsTask: Task<Void, Error>?

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `GeneratorProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<GeneratorRoute, Void>,
        services: Services,
        state: GeneratorState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)

        loadGeneratorOptionsTask = Task {
            try await loadGeneratorOptions()
        }
    }

    // MARK: Methods

    override func perform(_ effect: GeneratorEffect) async {
        switch effect {
        case .appeared:
            await reloadGeneratorOptions()
            await generateValue(shouldSavePassword: true)
            await checkLearnGeneratorActionCardEligibility()
        case .dismissLearnGeneratorActionCard:
            await services.stateService.setLearnGeneratorActionCardStatus(.complete)
            state.isLearnGeneratorActionCardEligible = false
        case .showLearnGeneratorGuidedTour:
            state.generatorType = .password
            await services.stateService.setLearnGeneratorActionCardStatus(.complete)
            state.isLearnGeneratorActionCardEligible = false
            state.guidedTourViewState.showGuidedTour = true
        }
    }

    override func receive(_ action: GeneratorAction) { // swiftlint:disable:this function_body_length
        var generateValueBehavior: GenerateValueBehavior? = action.shouldGenerateNewValue
            ? .generateNewValue(shouldSave: true)
            : nil

        switch action {
        case .copyGeneratedValue:
            services.pasteboardService.copy(state.generatedValue)
            state.showCopiedValueToast()
            Task {
                await services.reviewPromptService.trackUserAction(.copiedOrInsertedGeneratedValue)
            }
        case .dismissPressed:
            coordinator.navigate(to: .cancel)
        case let .emailTypeChanged(emailType):
            state.usernameState.updateEmailType(emailType)
        case let .generatorTypeChanged(generatorType):
            state.generatorType = generatorType
        case .refreshGeneratedValue:
            // Generating a new value happens below.
            break
        case .selectButtonPressed:
            coordinator.navigate(
                to: .complete(
                    type: state.generatorType,
                    value: state.generatedValue
                )
            )
            Task {
                await services.reviewPromptService.trackUserAction(.copiedOrInsertedGeneratedValue)
            }
        case .showPasswordHistory:
            coordinator.navigate(to: .generatorHistory)
        case let .sliderEditingChanged(_, isEditing):
            isEditingSlider = isEditing
            if !isEditing {
                // When the slider ends editing, save the existing generated value without generating a new one.
                generateValueBehavior = .saveExistingValue
            }
        case let .sliderValueChanged(field, value):
            guard state.shouldGenerateNewValueOnSliderValueChanged(value, keyPath: field.keyPath) else {
                generateValueBehavior = nil
                break
            }
            state[keyPath: field.keyPath] = value
            if isEditingSlider {
                generateValueBehavior = .generateNewValue(shouldSave: false)
            }
        case let .stepperValueChanged(field, value):
            state[keyPath: field.keyPath] = value
        case let .textFieldFocusChanged(keyPath):
            focusedKeyPath = keyPath
        case let .textFieldIsPasswordVisibleChanged(field, value):
            guard let isPasswordVisibleKeyPath = field.isPasswordVisibleKeyPath else { break }
            state[keyPath: isPasswordVisibleKeyPath] = value
        case let .textValueChanged(field, value):
            // SwiftUI TextField likes to send multiple changes via the binding. So if the text
            // field is equal to the state's value, return early.
            guard value != state[keyPath: field.keyPath] else { return }
            state[keyPath: field.keyPath] = value

            if field.keyPath == \.passwordState.wordSeparator, value.count > 1 {
                state[keyPath: field.keyPath] = String(value.prefix(1))
            }

            if let focusedKeyPath {
                let shouldGenerateNewValue = state.shouldGenerateNewValueOnTextValueChanged(keyPath: focusedKeyPath)
                generateValueBehavior = shouldGenerateNewValue ? .generateNewValue(shouldSave: true) : nil
            }
        case let .toastShown(newValue):
            state.toast = newValue
        case let .toggleValueChanged(field, isOn):
            state[keyPath: field.keyPath] = isOn
        case let .usernameForwardedEmailServiceChanged(forwardedEmailService):
            state.usernameState.forwardedEmailService = forwardedEmailService
        case let .usernameGeneratorTypeChanged(usernameGeneratorType):
            state.usernameState.usernameGeneratorType = usernameGeneratorType
        case let .guidedTourViewAction(action):
            state.guidedTourViewState.updateStateForGuidedTourViewAction(action)
        }

        if let generateValueBehavior {
            generateValueTask?.cancel()
            generateValueTask = Task {
                switch generateValueBehavior {
                case let .generateNewValue(shouldSave):
                    await generateValue(shouldSavePassword: shouldSave)
                case .saveExistingValue:
                    await saveExistingGeneratedValue()
                }
                await saveGeneratorOptions()
            }
        }
    }

    // MARK: Private

    /// Checks the eligibility of the generator Login action card.
    ///
    private func checkLearnGeneratorActionCardEligibility() async {
        state.isLearnGeneratorActionCardEligible = await services.stateService
            .getLearnGeneratorActionCardStatus() == .incomplete
    }

    /// Generate a new passphrase.
    ///
    /// - Parameter settings: The passphrase generator settings used to generate a new password.
    ///
    func generatePassphrase(settings: PassphraseGeneratorRequest) async {
        do {
            let passphrase = try await services.generatorRepository.generatePassphrase(
                settings: settings
            )
            try Task.checkCancellation()
            try await setGeneratedValue(passphrase)
        } catch is CancellationError {
            // No-op: don't log or alert for cancellation errors.
        } catch {
            Logger.application.error("Generator: error generating passphrase: \(error)")
        }
    }

    /// Generate a new password.
    ///
    /// - Parameters:
    ///   - settings: The password generator settings used to generate a new password.
    ///   - shouldSavePassword: Whether the generated password should be saved.
    ///
    func generatePassword(settings: PasswordGeneratorRequest, shouldSavePassword: Bool) async {
        do {
            let password = try await services.generatorRepository.generatePassword(
                settings: settings
            )
            try Task.checkCancellation()
            try await setGeneratedValue(password, shouldSavePassword: shouldSavePassword)
        } catch is CancellationError {
            // No-op: don't log or alert for cancellation errors.
        } catch {
            await coordinator.showErrorAlert(error: error)
            Logger.application.error("Generator: error generating password: \(error)")
        }
    }

    /// Generate a new username.
    ///
    func generateUsername() async {
        state.generatedValue = Constants.defaultGeneratedUsername
        do {
            guard let usernameGeneratorRequest = try state.usernameState.usernameGeneratorRequest() else {
                return
            }

            let username = try await services.generatorRepository.generateUsername(
                settings: usernameGeneratorRequest
            )
            try Task.checkCancellation()
            try await setGeneratedValue(username)
        } catch is CancellationError {
            // No-op: don't log or alert for cancellation errors.
        } catch {
            await coordinator.showErrorAlert(error: error)
            Logger.application.error("Generator: error generating username: \(error)")
        }
    }

    /// Generates a new value based on the current settings.
    ///
    /// - Parameter shouldSavePassword: Whether a generated password should be saved. This is
    ///     ignored if not generating a password.
    ///
    func generateValue(shouldSavePassword: Bool) async {
        do {
            // Wait for the generator options to finish loading before generating a value.
            try await loadGeneratorOptionsTask?.value

            switch state.generatorType {
            case .passphrase, .password:
                let (type, passwordState) = await validatePasswordOptionsAndApplyPolicies()
                // It's possible that applying a policy changes the generator type, so a second
                // switch on the type is needed.
                switch type {
                case .passphrase:
                    await generatePassphrase(settings: passwordState.passphraseGeneratorRequest)
                case .password:
                    await generatePassword(
                        settings: passwordState.passwordGeneratorRequest,
                        shouldSavePassword: shouldSavePassword
                    )
                case .username:
                    // We shouldn't get here since validating the password options shouldn't switch
                    // to the username generator.
                    await generateUsername()
                }
            case .username:
                await generateUsername()
            }
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    /// Fetches the user's saved generator options and updates the state with the previous selections.
    ///
    func loadGeneratorOptions() async throws {
        var passwordOptions = try await services.generatorRepository.getPasswordGenerationOptions()
        state.isPolicyInEffect = try await services.policyService.applyPasswordGenerationPolicy(
            options: &passwordOptions
        )
        state.setGeneratorType(passwordGeneratorType: passwordOptions.type)
        state.passwordState.update(with: passwordOptions)

        let usernameOptions = try await services.generatorRepository.getUsernameGenerationOptions()
        state.usernameState.update(with: usernameOptions)
        didLoadGeneratorOptions = true
    }

    /// Re-loads generator options.
    ///
    private func reloadGeneratorOptions() async {
        do {
            try await loadGeneratorOptions()
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Saves the existing generated value to the user's password history.
    ///
    /// This should only be called in the case where we want to save a previously generated value,
    /// which wasn't saved, but now should be saved. This supports generating new passwords as the
    /// length slider moves around but only saves the last password when the slider ends editing.
    ///
    func saveExistingGeneratedValue() async {
        guard state.generatorType == .password else { return }
        do {
            try await saveGeneratedValue(state.generatedValue)
        } catch {
            await coordinator.showErrorAlert(error: error)
            Logger.application.error("Generator: error generating username: \(error)")
        }
    }

    /// Saves the generated value to the user's password history.
    ///
    /// - Parameter value: The generated value to save to the user's password history.
    ///
    func saveGeneratedValue(_ value: String) async throws {
        try await services.generatorRepository.addPasswordHistory(
            PasswordHistoryView(
                password: value,
                lastUsedDate: Date()
            )
        )
    }

    /// Saves the user's generation options so their selections can be persisted across app launches.
    ///
    func saveGeneratorOptions() async {
        do {
            switch state.generatorType {
            case .passphrase, .password:
                let passwordOptions = state.passwordState.passwordGenerationOptions(generatorType: state.generatorType)
                try await services.generatorRepository.setPasswordGenerationOptions(passwordOptions)
            case .username:
                try await services.generatorRepository.setUsernameGenerationOptions(
                    state.usernameState.usernameGenerationOptions
                )
            }
        } catch {
            services.errorReporter.log(error: BitwardenError.generatorOptionsError(error: error))
        }
    }

    /// Sets a newly generated value to the state and saves it to the user's password history.
    ///
    /// - Parameters:
    ///   - value: The generated value.
    ///   - shouldSavePassword: Whether a generated password should be save. This is
    ///     ignored if not generating a password.
    ///
    func setGeneratedValue(_ value: String, shouldSavePassword: Bool = true) async throws {
        state.generatedValue = value
        if state.generatorType != .username, shouldSavePassword {
            try await saveGeneratedValue(value)
        }
    }

    /// Validates any password options to ensure the combination of options are valid and applies
    /// any policies to ensure a generated password conforms to the set policies.
    ///
    /// - Returns: A copy of the generator type and validated state, which can be used to generate
    ///     a new password or passphrase.
    ///
    func validatePasswordOptionsAndApplyPolicies() async -> (GeneratorType, GeneratorState.PasswordState) {
        state.passwordState.validateOptions()
        var passwordOptions = state.passwordState.passwordGenerationOptions(generatorType: state.generatorType)
        state.isPolicyInEffect = await (try? services.policyService
            .applyPasswordGenerationPolicy(options: &passwordOptions)) ?? false
        state.setGeneratorType(passwordGeneratorType: passwordOptions.type)
        state.passwordState.update(with: passwordOptions)

        var policyOptions = PasswordGenerationOptions()
        _ = try? await services.policyService.applyPasswordGenerationPolicy(options: &policyOptions)
        state.policyOptions = policyOptions

        // Return the validated state to prevent any race conditions of the state being updated
        // before the value is generated.
        return (state.generatorType, state.passwordState)
    }
} // swiftlint:disable:this file_length
