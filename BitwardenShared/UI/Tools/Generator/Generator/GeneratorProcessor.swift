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
    private let coordinator: AnyCoordinator<GeneratorRoute>

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
        coordinator: AnyCoordinator<GeneratorRoute>,
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
        case let .generatorTypeChanged(generatorType):
            state.generatorType = generatorType
        case let .passwordGeneratorTypeChanged(passwordGeneratorType):
            state.passwordState.passwordGeneratorType = passwordGeneratorType
        case .refreshGeneratedValue:
            // Generating a new value happens below.
            break
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

            if focusedKeyPath == \.usernameState.email || focusedKeyPath == \.usernameState.domain {
                // Don't generate a new value on every character input, wait until focus leaves the field.
                shouldGenerateNewValue = false
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
            state.generatedValue = passphrase
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
            state.generatedValue = password
        } catch {
            Logger.application.error("Generator: error generating password: \(error)")
        }
    }

    /// Generate a new username.
    ///
    func generateUsername() async {
        do {
            let username: String
            switch state.usernameState.usernameGeneratorType {
            case .catchAllEmail:
                // TODO: BIT-396 Generate catch-all email
                username = "-"
            case .forwardedEmail:
                // TODO: BIT-406 Generate forwarded email
                username = "-"
            case .plusAddressedEmail:
                username = try await services.generatorRepository.generateUsernamePlusAddressedEmail(
                    email: state.usernameState.email
                )
            case .randomWord:
                // TODO: BIT-407 Generate random word
                username = "-"
            }
            try Task.checkCancellation()
            state.generatedValue = username
        } catch {
            Logger.application.error("Generator: error generating username: \(error)")
        }
    }

    /// Generates a new value based on the current settings.
    ///
    func generateValue() async {
        switch state.generatorType {
        case .password:
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
        } catch {
            services.errorReporter.log(error: BitwardenError.generatorOptionsError(error: error))
        }
    }

    /// Saves the user's generation options so their selections can be persisted across app launches.
    ///
    func saveGeneratorOptions() async {
        do {
            try await services.generatorRepository.setPasswordGenerationOptions(
                state.passwordState.passwordGenerationOptions
            )
        } catch {
            services.errorReporter.log(error: BitwardenError.generatorOptionsError(error: error))
        }
    }
}
