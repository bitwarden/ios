import Foundation
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

    typealias Services = HasAuthRepository
        & HasBiometricsService
        & HasErrorReporter
        & HasSettingsRepository
        & HasStateService
        & HasTwoStepLoginService

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
        case .appeared:
            Task {
                do {
                    let userId = try await services.stateService.getActiveAccountId()
                    let key = try await services.stateService.pinKeyEncryptedUserKey(userId: userId)
                    if try await services.stateService.pinKeyEncryptedUserKey(userId: userId) != nil {
                        state.isUnlockWithPINCodeOn = true
                    }
                } catch {}
            }
        case .lockVault:
            do {
                let account = try await services.stateService.getActiveAccount()
                await services.settingsRepository.lockVault(userId: account.profile.userId)
                coordinator.navigate(to: .lockVault(account: account))
            } catch {
                coordinator.navigate(to: .logout)
                services.errorReporter.log(error: error)
            }
        }
    }

    override func receive(_ action: AccountSecurityAction) {
        switch action {
        case .clearTwoStepLoginUrl:
            state.twoStepLoginUrl = nil
        case .deleteAccountPressed:
            coordinator.navigate(to: .deleteAccount)
        case .logout:
            showLogoutConfirmation()
        case let .sessionTimeoutActionChanged(action):
            saveTimeoutActionSetting(action)
        case let .sessionTimeoutValueChanged(newValue):
            state.sessionTimeoutValue = newValue
        case let .setCustomSessionTimeoutValue(newValue):
            state.customSessionTimeoutValue = newValue
        case let .toggleApproveLoginRequestsToggle(isOn):
            state.isApproveLoginRequestsToggleOn = isOn
        case let .toggleUnlockWithFaceID(isOn):
            state.isUnlockWithFaceIDOn = isOn
        case let .toggleUnlockWithPINCode(isOn):
            toggleUnlockWithPIN(isOn)
        case let .toggleUnlockWithTouchID(isOn):
            state.isUnlockWithTouchIDToggleOn = isOn
        case .twoStepLoginPressed:
            showTwoStepLoginAlert()
        }
    }

    // MARK: Private

    /// Saves the user's session timeout action.
    ///
    /// - Parameter action: The action to perform on session timeout.
    ///
    private func saveTimeoutActionSetting(_ action: SessionTimeoutAction) {
        guard action != state.sessionTimeoutAction else { return }
        if action == .logout {
            coordinator.navigate(to: .alert(.logoutOnTimeoutAlert {
                // TODO: BIT-1125 Persist the setting
                self.state.sessionTimeoutAction = action
            }))
        } else {
            // TODO: BIT-1125 Persist the setting
            state.sessionTimeoutAction = action
        }
    }

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

    /// Shows the two step login alert. If `Yes` is selected, the user will be
    /// navigated to the web app.
    ///
    private func showTwoStepLoginAlert() {
        coordinator.navigate(to: .alert(.twoStepLoginAlert {
            self.state.twoStepLoginUrl = self.services.twoStepLoginService.twoStepLoginUrl()
        }))
    }

    /// Shows an alert prompting the user to enter their PIN. If set successfully, the toggle will be turned on.
    ///
    /// - Parameter isOn: Whether or not the toggle value is true or false.
    ///
    private func toggleUnlockWithPIN(_ isOn: Bool) {
        if isOn {
            coordinator.navigate(to: .alert(.enterPINCode(completion: { pin in
                self.coordinator.navigate(to: .alert(.unlockWithPINCodeAlert {
                    do {
                        try await self.services.authRepository.setPinKeyEncryptedUserKey(pin: pin)
                        self.state.isUnlockWithPINCodeOn = true
                    } catch {
                        self.coordinator.navigate(to: .alert(.defaultAlert(title: Localizations.anErrorHasOccurred)))
                    }
                }))
            })))
        } else {
            Task {
                do {
                    let userId = try await services.stateService.getActiveAccountId()
                    try await self.services.stateService.setPinKeyEncryptedUserKey(nil, userId: userId)
                    state.isUnlockWithPINCodeOn = isOn
                } catch {
                    self.coordinator.navigate(to: .alert(.defaultAlert(title: Localizations.anErrorHasOccurred)))
                }
            }
        }
    }
}
