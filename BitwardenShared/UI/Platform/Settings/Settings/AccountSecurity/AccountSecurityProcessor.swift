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
        & HasPolicyService
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
            setVaultTimeout(value: .custom(newValue))
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
            setVaultTimeout(value: newValue)
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
            if let policy = try await services.policyService.fetchTimeoutPolicyValues() {
                // If the policy returns no timeout action, we present the user all timeout actions.
                // If the policy returns a timeout action, it's the only one we show the user.
                if policy.action != nil {
                    state.policyTimeoutAction = policy.action
                }

                state.policyTimeoutValue = policy.value
                state.isTimeoutPolicyEnabled = true
            }

            state.sessionTimeoutValue = try await services.stateService.getVaultTimeout()
            state.sessionTimeoutAction = try await services.stateService.getTimeoutAction()
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

            if try await services.authRepository.isPinUnlockAvailable() {
                state.isUnlockWithPINCodeOn = true
            }
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
                    self.state.sessionTimeoutAction = action
                } catch {
                    self.coordinator.navigate(to: .alert(.defaultAlert(title: Localizations.anErrorHasOccurred)))
                    self.services.errorReporter.log(error: error)
                }
            }))
        } else {
            Task {
                try await services.stateService.setTimeoutAction(action: action)
            }
            state.sessionTimeoutAction = action
        }
    }

    /// Sets the vault timeout value.
    ///
    /// - Parameter value: The vault timeout value.
    ///
    private func setVaultTimeout(value: SessionTimeoutValue) {
        Task {
            do {
                if state.isTimeoutPolicyEnabled {
                    // If the user's selection exceeds the policy's limit,
                    // show an alert, and set their timeout value equal to the policy max.
                    guard value.rawValue <= state.policyTimeoutValue else {
                        try await services.vaultTimeoutService.setVaultTimeout(
                            value: SessionTimeoutValue(rawValue: state.policyTimeoutValue),
                            userId: nil
                        )
                        coordinator.navigate(to: .alert(.timeoutExceedsPolicyLengthAlert()))
                        return
                    }
                }
                try await services.vaultTimeoutService.setVaultTimeout(value: value, userId: nil)
                state.sessionTimeoutValue = value
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
            let phrase = try await services.authRepository.getFingerprintPhrase()

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
        if isOn {
            coordinator.navigate(to: .alert(.enterPINCode(completion: { pin in
                self.coordinator.navigate(to: .alert(.unlockWithPINCodeAlert { requirePassword in
                    do {
                        try await self.services.authRepository.setPins(
                            pin,
                            requirePasswordAfterRestart: requirePassword
                        )
                        self.state.isUnlockWithPINCodeOn = isOn
                    } catch {
                        self.coordinator.navigate(to: .alert(.defaultAlert(
                            title: Localizations.anErrorHasOccurred
                        )))
                    }
                }))
            })))
        } else {
            Task {
                do {
                    try await self.services.authRepository.clearPins()
                    state.isUnlockWithPINCodeOn = isOn
                } catch {
                    self.coordinator.navigate(to: .alert(.defaultAlert(title: Localizations.anErrorHasOccurred)))
                }
            }
        }
    }
}
