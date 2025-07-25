import BitwardenResources

// MARK: - MasterPasswordGeneratorProcessor

/// The processor used to manage state and handle actions for the generate master password screen.
///
class MasterPasswordGeneratorProcessor: StateProcessor<
    MasterPasswordGeneratorState,
    MasterPasswordGeneratorAction,
    MasterPasswordGeneratorEffect
> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasGeneratorRepository

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The delegate used to communiate saving a new generated password.
    private weak var delegate: MasterPasswordUpdateDelegate?

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `MasterPasswordGeneratorProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate for the processor to notifiy saving a generated password.
    ///   - services: The services required by this processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        delegate: MasterPasswordUpdateDelegate?,
        services: Services
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: MasterPasswordGeneratorState())
    }

    // MARK: Methods

    override func perform(_ effect: MasterPasswordGeneratorEffect) async {
        switch effect {
        case .generate,
             .loadData:
            await generatePassword()
        case .save:
            delegate?.didUpdateMasterPassword(password: state.generatedPassword)
            coordinator.navigate(to: .dismissPresented)
        }
    }

    override func receive(_ action: MasterPasswordGeneratorAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismissPresented)
        case let .masterPasswordChanged(newValue):
            state.generatedPassword = newValue
        case .preventAccountLock:
            coordinator.navigate(to: .preventAccountLock)
        }
    }

    // MARK: Private Methods

    /// Generates a new master password asynchronously and updates the state.
    ///
    private func generatePassword() async {
        do {
            state.generatedPassword = try await services.generatorRepository.generateMasterPassword()
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }
}
