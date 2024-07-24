// MARK: - ExpiredLinkProcessor

/// The processor used to manage state and handle actions for the passwort hint screen.
///
class ExpiredLinkProcessor: StateProcessor<ExpiredLinkState, ExpiredLinkAction, Void> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    // MARK: Initialization

    /// Creates a new `ExpiredLinkProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        state: ExpiredLinkState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: ExpiredLinkAction) {
        switch action {
        case .dismissTapped,
                .logInTapped:
            coordinator.navigate(to: .dismiss)
        case .restartRegistrationTapped:
            coordinator.navigate(to: .dismissPresented)
        }
    }
}
