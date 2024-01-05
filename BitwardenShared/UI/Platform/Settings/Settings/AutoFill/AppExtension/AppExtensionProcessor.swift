// MARK: - AppExtensionProcessor

/// The processor used to manage state and handle actions for the `AppExtensionView`.
///
final class AppExtensionProcessor: StateProcessor<AppExtensionState, AppExtensionAction, Void> {
    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    // MARK: Initialization

    /// Initializes a `AppExtensionProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        state: AppExtensionState
    ) {
        self.coordinator = coordinator

        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: AppExtensionAction) {
        switch action {
        case .activateButtonTapped:
            break
        }
    }
}
