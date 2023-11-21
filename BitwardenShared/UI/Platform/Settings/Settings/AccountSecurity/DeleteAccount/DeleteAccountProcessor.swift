// MARK: - DeleteAccountProcessor

/// The processor used to manage state and handle actions for the delete account screen.
///
final class DeleteAccountProcessor: StateProcessor<DeleteAccountState, DeleteAccountAction, DeleteAccountEffect> {
    // MARK: Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    // MARK: Initialization

    /// Initializes a `DeleteAccountProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        state: DeleteAccountState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: DeleteAccountAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        }
    }
}
