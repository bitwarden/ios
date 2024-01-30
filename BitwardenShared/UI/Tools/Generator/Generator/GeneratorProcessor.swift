import BitwardenSdk
import OSLog

/// The processor used to manage state and handle actions for the generator screen.
///
final class GeneratorProcessor: StateProcessor<GeneratorState, GeneratorAction, GeneratorEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasGeneratorRepository
        & HasPasteboardService

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<GeneratorRoute, Void>

    /// The key path of the currently focused text field.
    private var focusedKeyPath: KeyPath<GeneratorState, String>?

    /// The task used to generate a new value so it can be cancelled if needed.
    private var generateValueTask: Task<Void, Never>?

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

        Task {
            await loadGeneratorOptions()
        }
    }

    // MARK: Methods

    override func perform(_ effect: GeneratorEffect) async {
        switch effect {
        case .appeared:
            await generateValue()
        }
    }

    override func receive(_ action: GeneratorAction) { // swiftlint:disable:this function_body_length
        var shouldGenerateNewValue = action.shouldGenerateNewValue

        switch action {
        case .copyGeneratedValue:
            services.pasteboardService.copy(state.generatedValue)
            state.showCopiedValueToast()
        case .dismissPressed:
            coordinator.navigate(to: .cancel)
        case let .emailTypeChanged(emailType):
            state.usernameState.updateEmailType(emailType)
        case let .generatorTypeChanged(generatorType):
            state.generatorType = generatorType
        case let .passwordGeneratorTypeChanged(passwordGeneratorType):
            state.passwordState.passwordGeneratorType = passwordGeneratorType
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
        case .showPasswordHistory:
            coordinator.navigate(to: .generatorHistory)
        case let .sliderValueChanged(field, value):
            state[keyPath: field.keyPath] = value
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
                shouldGenerateNewValue = state.shouldGenerateNewValueOnTextValueChanged(keyPath: focusedKeyPath)
            }
        case let .toastShown(newValue):
            state.toast = newValue
        case let .toggleValueChanged(field, isOn):
            state[keyPath: field.keyPath] = isOn
        case let .usernameForwardedEmailServiceChanged(forwardedEmailService):
            state.usernameState.forwardedEmailService = forwardedEmailService
        case let .usernameGeneratorTypeChanged(usernameGeneratorType):
            state.usernameState.usernameGeneratorType = usernameGeneratorType
        }

        if shouldGenerateNewValue {
            generateValueTask?.cancel()
            generateValueTask = Task {
                await generateValue()
            }
        }

        if action.shouldPersistGeneratorOptions {
            Task {
                await saveGeneratorOptions()
            }
        }
    }

    // MARK: Private

    /// Generate a new passphrase.
    ///
    func generatePassphrase() async {
        do {
            let passphrase = try await services.generatorRepository.generatePassphrase(
                settings: state.passwordState.passphraseGeneratorRequest
            )
            try Task.checkCancellation()
            try await setGeneratedValue(passphrase)
        } catch {
            Logger.application.error("Generator: error generating passphrase: \(error)")
        }
    }

    /// Generate a new password.
    ///
    func generatePassword() async {
        do {
            let password = try await services.generatorRepository.generatePassword(
                settings: state.passwordState.passwordGeneratorRequest
            )
            try Task.checkCancellation()
            try await setGeneratedValue(password)
        } catch is CancellationError {
            // No-op: don't log or alert for cancellation errors.
        } catch {
            coordinator.showAlert(.networkResponseError(error))
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
            coordinator.showAlert(.networkResponseError(error))
            Logger.application.error("Generator: error generating username: \(error)")
        }
    }

    /// Generates a new value based on the current settings.
    ///
    func generateValue() async {
        switch state.generatorType {
        case .password:
            state.passwordState.validateOptions()
            switch state.passwordState.passwordGeneratorType {
            case .passphrase:
                await generatePassphrase()
            case .password:
                await generatePassword()
            }
        case .username:
            await generateUsername()
        }
    }

    /// Fetches the user's saved generator options and updates the state with the previous selections.
    ///
    func loadGeneratorOptions() async {
        do {
            let passwordOptions = try await services.generatorRepository.getPasswordGenerationOptions()
            state.passwordState.update(with: passwordOptions)

            let usernameOptions = try await services.generatorRepository.getUsernameGenerationOptions()
            state.usernameState.update(with: usernameOptions)
        } catch {
            services.errorReporter.log(error: BitwardenError.generatorOptionsError(error: error))
        }
    }

    /// Saves the user's generation options so their selections can be persisted across app launches.
    ///
    func saveGeneratorOptions() async {
        do {
            switch state.generatorType {
            case .password:
                try await services.generatorRepository.setPasswordGenerationOptions(
                    state.passwordState.passwordGenerationOptions
                )
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
    /// - Parameter value: The generated value.
    ///
    func setGeneratedValue(_ value: String) async throws {
        state.generatedValue = value
        if state.generatorType == .password {
            try await services.generatorRepository.addPasswordHistory(
                PasswordHistoryView(
                    password: value,
                    lastUsedDate: Date()
                )
            )
        }
    }
}
