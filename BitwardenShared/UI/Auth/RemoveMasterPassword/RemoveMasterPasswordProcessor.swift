// MARK: - RemoveMasterPasswordProcessor

/// The processor used to manage state and handle actions for the remove master password screen.
///
class RemoveMasterPasswordProcessor: StateProcessor<RemoveMasterPasswordState, RemoveMasterPasswordAction, Void> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    // MARK: Initialization

    /// Creates a new `RemoveMasterPasswordProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        state: RemoveMasterPasswordState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: RemoveMasterPasswordAction) {
        switch action {
        case .continueFlow:
            // TODO: PM-11152 Key connector migration
            break
        }
    }
}
