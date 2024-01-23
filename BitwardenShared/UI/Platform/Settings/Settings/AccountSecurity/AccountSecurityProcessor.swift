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
        & HasClientAuth
        & HasErrorReporter
        & HasSettingsRepository
        & HasStateService
        & HasTimeProvider
        & HasTwoStepLoginService
        & HasVaultTimeoutService

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

    override func perform(_ effect: AccountSecurityEffect) async {
        switch effect {
        case .accountFingerprintPhrasePressed:
            await showAccountFingerprintPhraseAlert()
        case .appeared:
            await appeared()
        case .loadData:
            await loadData()
        case let .lockVault(userIntiated):
            await lockVault(userInitiated: userIntiated)
        case let .toggleUnlockWithBiometrics(isOn):
            await setBioMetricAuth(isOn)
        }
    }

    override func receive(_ action: AccountSecurityAction) {
        switch action {
        case .clearFingerprintPhraseUrl:
            state.fingerprintPhraseUrl = nil
        case .clearTwoStepLoginUrl:
            state.twoStepLoginUrl = nil
        case let .customTimeoutValueChanged(newValue):
            state.customTimeoutValue = newValue
            setVaultTimeout(value: newValue)
        case .deleteAccountPressed:
            coordinator.navigate(to: .deleteAccount)
        case .logout:
            showLogoutConfirmation()
        case .pendingLoginRequestsTapped:
            coordinator.navigate(to: .pendingLoginRequests)
        case let .sessionTimeoutActionChanged(newValue):
            setTimeoutAction(newValue)
        case let .sessionTimeoutValueChanged(newValue):
            state.sessionTimeoutValue = newValue
            setVaultTimeout(value: newValue.rawValue)
        case let .toggleApproveLoginRequestsToggle(isOn):
            confirmTogglingApproveLoginRequests(isOn)
        case let .toggleUnlockWithPINCode(isOn):
            toggleUnlockWithPIN(isOn)
        case .twoStepLoginPressed:
            showTwoStepLoginAlert()
        }
    }

    // MARK: Private

    /// The view has appeared.
    ///
    private func appeared() async {
        do {
            let timeoutAction = try await services.stateService.getTimeoutAction()
            let vaultTimeout = try await services.stateService.getVaultTimeout()

            if timeoutAction == nil {
                try await services.stateService.setTimeoutAction(action: .lock)
            }

            state.sessionTimeoutAction = try await services.stateService.getTimeoutAction() ?? .lock

            if vaultTimeout == -1 {
                state.sessionTimeoutValue = .onAppRestart
            } else if vaultTimeout == -2 {
                state.sessionTimeoutValue = .never
            } else {
                var rawTimeoutValues: [Int] = []
                for value in SessionTimeoutValue.allCases {
                    rawTimeoutValues.append(value.rawValue)
                }
                if !rawTimeoutValues.contains(vaultTimeout) {
                    state.sessionTimeoutValue = .custom
                    state.customTimeoutValue = vaultTimeout
                } else {
                    for (_, value) in state.vaultTimeoutValues where vaultTimeout == value.rawValue {
                        state.sessionTimeoutValue = value
                    }
                }
            }
        } catch {
            coordinator.navigate(to: .alert(.defaultAlert(title: Localizations.anErrorHasOccurred)))
            services.errorReporter.log(error: error)
        }
    }

    /// Show an alert to confirm enabling approving login requests.
    ///
    /// - Parameter isOn: Whether or not the toggle value is true or false.
    ///
    private func confirmTogglingApproveLoginRequests(_ isOn: Bool) {
        // If the user is attempting to turn the toggle on, show an alert to confirm first.
        if isOn {
            coordinator.showAlert(.confirmApproveLoginRequests {
                await self.toggleApproveLoginRequests(isOn)
            })
        } else {
            Task { await toggleApproveLoginRequests(isOn) }
        }
    }

    /// Load any initial data for the view.
    private func loadData() async {
        do {
            state.biometricUnlockStatus = await loadBiometricUnlockPreference()
            state.isApproveLoginRequestsToggleOn = try await services.stateService.getApproveLoginRequests()
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Loads the state of the user's biometric unlock preferences.
    ///
    /// - Returns: The `BiometricsUnlockStatus` for the user.
    ///
    private func loadBiometricUnlockPreference() async -> BiometricsUnlockStatus {
        do {
            let biometricsStatus = try await services.biometricsService.getBiometricUnlockStatus()
            return biometricsStatus
        } catch {
            Logger.application.debug("Error loading biometric preferences: \(error)")
            return .notAvailable
        }
    }

    /// Locks the user's vault
    ///
    ///
    ///
    private func lockVault(userInitiated: Bool) async {
        do {
            let account = try await services.stateService.getActiveAccount()
            await services.authRepository.lockVault(userId: account.profile.userId)
            coordinator.navigate(to: .lockVault(account: account, userInitiated: userInitiated))
        } catch {
            coordinator.navigate(to: .logout(userInitiated: userInitiated))
            services.errorReporter.log(error: error)
        }
    }

    /// Sets the session timeout action.
    ///
    /// - Parameter action: The action that occurs upon a session timeout.
    ///
    private func setTimeoutAction(_ action: SessionTimeoutAction) {
        guard action != state.sessionTimeoutAction else { return }
        if action == .logout {
            coordinator.navigate(to: .alert(.logoutOnTimeoutAlert {
                do {
                    try await self.services.stateService.setTimeoutAction(action: action)
                } catch {
                    self.coordinator.navigate(to: .alert(.defaultAlert(title: Localizations.anErrorHasOccurred)))
                    self.services.errorReporter.log(error: error)
                }
            }))
        } else {
            Task {
                try await services.stateService.setTimeoutAction(action: action)
            }
        }

        state.sessionTimeoutAction = action
    }

    /// Sets the vault timeout value.
    ///
    /// - Parameter value: The vault timeout value.
    ///
    private func setVaultTimeout(value: Int) {
        Task {
            do {
                if value == -100 {
                    try await services.vaultTimeoutService.setVaultTimeout(value: 60, userId: nil)
                } else {
                    try await services.vaultTimeoutService.setVaultTimeout(value: value, userId: nil)
                }
            } catch {
                self.coordinator.navigate(to: .alert(.defaultAlert(title: Localizations.anErrorHasOccurred)))
                self.services.errorReporter.log(error: error)
            }
        }
    }

    /// Shows the account fingerprint phrase alert.
    ///
    private func showAccountFingerprintPhraseAlert() async {
        do {
            let userId = try await services.stateService.getActiveAccountId()
            let phrase = try await services.authRepository.getFingerprintPhrase(userId: userId)

            coordinator.navigate(to: .alert(
                .displayFingerprintPhraseAlert({
                    self.state.fingerprintPhraseUrl = ExternalLinksConstants.fingerprintPhrase
                }, phrase: phrase)
            ))
        } catch {
            coordinator.navigate(to: .alert(.defaultAlert(title: Localizations.anErrorHasOccurred)))
        }
    }

    /// Shows an alert asking the user to confirm that they want to logout.
    private func showLogoutConfirmation() {
        let alert = Alert.logoutConfirmation {
            do {
                try await self.services.authRepository.logout()
            } catch {
                self.services.errorReporter.log(error: error)
            }
            self.coordinator.navigate(to: .logout(userInitiated: true))
        }
        coordinator.navigate(to: .alert(alert))
    }

    /// Shows the two step login alert. If `Yes` is selected, the user will be navigated to the web app.
    private func showTwoStepLoginAlert() {
        coordinator.navigate(to: .alert(.twoStepLoginAlert {
            self.state.twoStepLoginUrl = self.services.twoStepLoginService.twoStepLoginUrl()
        }))
    }

    /// Sets the user's biometric auth
    ///
    /// - Parameter enabled: Whether or not the the user wants biometric auth enabled.
    ///
    private func setBioMetricAuth(_ enabled: Bool) async {
        do {
            try await services.authRepository.allowBioMetricUnlock(enabled, userId: nil)
            state.biometricUnlockStatus = try await services.biometricsService.getBiometricUnlockStatus()
            // Set biometric integrity if needed.
            if case .available(_, true, false) = state.biometricUnlockStatus {
                try await services.biometricsService.configureBiometricIntegrity()
                state.biometricUnlockStatus = try await services.biometricsService.getBiometricUnlockStatus()
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Update the value of the approve login requests setting in the state and the cached data.
    ///
    /// - Parameter isOn: Whether or not the toggle value is true or false.
    ///
    private func toggleApproveLoginRequests(_ isOn: Bool) async {
        do {
            try await services.stateService.setApproveLoginRequests(isOn)
            state.isApproveLoginRequestsToggleOn = isOn
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Shows an alert prompting the user to enter their PIN. If set successfully, the toggle will be turned on.
    ///
    /// - Parameter isOn: Whether or not the toggle value is true or false.
    ///
    private func toggleUnlockWithPIN(_ isOn: Bool) {
        if !state.isUnlockWithPINCodeOn {
            coordinator.navigate(
                to: .alert(
                    .enterPINCode(completion: { _ in
                        self.state.isUnlockWithPINCodeOn = isOn
                    })
                )
            )
        } else {
            state.isUnlockWithPINCodeOn = isOn
        }
    }
}
