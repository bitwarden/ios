/// The processor used to manage state and handle actions for the settings screen.
///
final class SettingsProcessor: StateProcessor<SettingsState, SettingsAction, Void> {
    // MARK: Types

    typealias Services = HasSettingsRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `SettingsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        services: Services,
        state: SettingsState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: SettingsAction) {
        switch action {
        case .logout:
            showLogoutConfirmation()
        }
    }

    // MARK: Private

    /// Shows an alert asking the user to confirm that they want to logout.
    ///
    private func showLogoutConfirmation() {
        let alert = Alert.logoutConfirmation {
            try? await self.services.settingsRepository.logout()
            self.coordinator.navigate(to: .logout)
        }
        coordinator.navigate(to: .alert(alert))
    }
}
