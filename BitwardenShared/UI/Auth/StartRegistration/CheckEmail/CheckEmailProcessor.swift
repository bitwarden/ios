// MARK: - CheckEmailProcessor

/// The processor used to manage state and handle actions for the check email screen.
///
class CheckEmailProcessor: StateProcessor<CheckEmailState, CheckEmailAction, Void> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    // MARK: Initialization

    /// Creates a new `CheckEmailProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        state: CheckEmailState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: CheckEmailAction) {
        switch action {
        case .logInTapped:
            coordinator.navigate(to: .dismiss)
        case .dismissTapped,
             .goBackTapped:
            coordinator.navigate(to: .dismissPresented)
        }
    }
}
