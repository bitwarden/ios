// MARK: - SettingsProcessor

/// The processor used to manage state and handle actions for the settings screen.
///
final class SettingsProcessor: StateProcessor<SettingsState, SettingsAction, Void> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasSettingsRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    // MARK: Initialization

    /// Creates a new `SettingsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        state: SettingsState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: SettingsAction) {
        switch action {
        case .accountSecurityPressed:
            coordinator.navigate(to: .accountSecurity)
        case .autoFillPressed:
            coordinator.navigate(to: .autoFill)
        }
    }
}
