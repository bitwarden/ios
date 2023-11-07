import OSLog

// MARK: - AccountSecurityProcessor

final class AccountSecurityProcessor: StateProcessor<AccountSecurityState, AccountSecurityAction, Void> {
    // MARK: Types

    typealias Services = HasSettingsRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `AccountSecurityProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        services: Services,
        state: AccountSecurityState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: AccountSecurityAction) {
        switch action {
        case .logout:
            showLogoutConfirmation()
        case let .toggleApproveLoginRequestsToggle(isOn):
            state.isApproveLoginRequestsToggleOn = isOn
        case let .toggleUnlockWithFaceID(isOn):
            state.isUnlockWithFaceIDOn = isOn
        case let .toggleUnlockWithPINCode(isOn):
            state.isUnlockWithPINCodeOn = isOn
        case let .toggleUnlockWithTouchID(isOn):
            state.isUnlockWithTouchIDToggleOn = isOn
        }
    }

    // MARK: Private

    /// Shows an alert asking the user to confirm that they want to logout.
    ///
    private func showLogoutConfirmation() {
        let alert = Alert.logoutConfirmation {
            do {
                try await self.services.settingsRepository.logout()
            } catch {
                // TODO: BIT-941 Log error to Crashlytics.
                Logger.processor.error("Error logging out: \(error)")
                assertionFailure("Error logging out: \(error)")
            }
            self.coordinator.navigate(to: .logout)
        }
        coordinator.navigate(to: .alert(alert))
    }
}
