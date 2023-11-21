import OSLog

// MARK: - AccountSecurityProcessor

/// The processor used to manage state and handle actions for the account security screen.
///
final class AccountSecurityProcessor: StateProcessor<
    AccountSecurityState,
    AccountSecurityAction,
    AccountSecurityEffect
> {
    // MARK: Types

    typealias Services = HasBiometricsService
        & HasErrorReporter
        & HasSettingsRepository
        & HasStateService

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
        var state = state
        state.biometricAuthenticationType = services.biometricsService.getBiometricAuthenticationType()

        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AccountSecurityEffect) async {
        switch effect {
        case .lockVault:
            services.settingsRepository.lockVault()

            do {
                let account = try await services.stateService.getActiveAccount()
                coordinator.navigate(to: .lockVault(account: account))
            } catch {
                coordinator.navigate(to: .logout)
                services.errorReporter.log(error: error)
            }
        }
    }

    override func receive(_ action: AccountSecurityAction) {
        switch action {
        case .deleteAccountPressed:
            coordinator.navigate(to: .deleteAccount)
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
                self.services.errorReporter.log(error: error)
            }
            self.coordinator.navigate(to: .logout)
        }
        coordinator.navigate(to: .alert(alert))
    }
}
