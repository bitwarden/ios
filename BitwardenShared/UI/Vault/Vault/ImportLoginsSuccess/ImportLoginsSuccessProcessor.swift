// MARK: - ImportLoginsSuccessProcessor

/// The processor used to manage state and handle actions for the import logins success screen.
///
class ImportLoginsSuccessProcessor: StateProcessor<Void, ImportLoginsSuccessAction, Void> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<VaultRoute, AuthAction>

    // MARK: Initialization

    /// Creates a new `ImportLoginsSuccessProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<VaultRoute, AuthAction>) {
        self.coordinator = coordinator
        super.init()
    }

    // MARK: Methods

    override func receive(_ action: ImportLoginsSuccessAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        }
    }
}
