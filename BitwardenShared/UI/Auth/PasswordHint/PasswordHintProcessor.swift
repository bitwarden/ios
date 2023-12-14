// MARK: - PasswordHintProcessor

/// The processor used to manage state and handle actions for the passwort hint screen.
///
class PasswordHintProcessor: StateProcessor<PasswordHintState, PasswordHintAction, PasswordHintEffect> {
    // MARK: Types

    typealias Services = HasAppSettingsStore
        & HasAuthRepository
        & HasEnvironmentService
        & HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `LandingProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        services: Services,
        state: PasswordHintState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: PasswordHintEffect) async {
        switch effect {
        case .submitPressed:
            print("submit button pressed")
        }
    }

    override func receive(_ action: PasswordHintAction) {
        switch action {
        case .dismissPressed:
            coordinator.navigate(to: .dismiss)
        case let .emailAddressChanged(newValue):
            state.emailAddress = newValue
        }
    }
}
