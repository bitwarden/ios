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
        & HasBiometricsRepository
        & HasClientAuth
        & HasErrorReporter
        & HasPolicyService
        & HasSettingsRepository
        & HasStateService
        & HasTimeProvider
        & HasTwoStepLoginService

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

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
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
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
        case .lockVault:
            await coordinator.handleEvent(
                .authAction(
                    .lockVault(
                        userId: nil
                    )
                )
            )
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
            setVaultTimeout(value: newValue)
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
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Load any initial data for the view.
    private func loadData() async {
        do {
            state.biometricUnlockStatus = await loadBiometricUnlockPreference()

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
            let biometricsStatus = try await services.biometricsRepository.getBiometricUnlockStatus()
            return biometricsStatus
        } catch {
            Logger.application.debug("Error loading biometric preferences: \(error)")
            return .notAvailable
        }
    }

    /// Sets the session timeout action.
    ///
    /// - Parameter action: The action that occurs upon a session timeout.
    ///
    private func setTimeoutAction(_ action: SessionTimeoutAction) {
        guard action != state.sessionTimeoutAction else { return }
        if action == .logout {
            coordinator.showAlert(.logoutOnTimeoutAlert {
                do {
                    try await self.services.stateService.setTimeoutAction(action: action)
                    self.state.sessionTimeoutAction = action
                } catch {
                    self.coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
                    self.services.errorReporter.log(error: error)
                }
            })
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
        let errorHandler: (Error) -> Void = { error in
            self.coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            self.services.errorReporter.log(error: error)
        }
        Task {
            do {
                if state.isTimeoutPolicyEnabled {
                    // If the user's selection exceeds the policy's limit,
                    // show an alert, and set their timeout value equal to the policy max.
                    guard value.rawValue <= state.policyTimeoutValue else {
                        try await services.authRepository.setVaultTimeout(
                            value: SessionTimeoutValue(rawValue: state.policyTimeoutValue)
                        )
                        coordinator.showAlert(.timeoutExceedsPolicyLengthAlert())
                        return
                    }
                }
                let setTimeoutAction = { [weak self] in
                    guard let self else { return }
                    do {
                        try await services.authRepository.setVaultTimeout(value: value)
                        state.sessionTimeoutValue = value
                    } catch {
                        errorHandler(error)
                    }
                }
                if value == .never {
                    coordinator.showAlert(.neverLockAlert(action: setTimeoutAction))
                } else {
                    await setTimeoutAction()
                }
            } catch {
                errorHandler(error)
            }
        }
    }

    /// Shows the account fingerprint phrase alert.
    ///
    private func showAccountFingerprintPhraseAlert() async {
        do {
            let phrase = try await services.authRepository.getFingerprintPhrase()

            coordinator.showAlert(.displayFingerprintPhraseAlert(phrase: phrase) {
                self.state.fingerprintPhraseUrl = ExternalLinksConstants.fingerprintPhrase
            })
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    /// Shows an alert asking the user to confirm that they want to logout.
    private func showLogoutConfirmation() {
        coordinator.showAlert(.logoutConfirmation {
            await self.coordinator.handleEvent(
                .authAction(
                    .logout(userId: nil, userInitiated: true)
                )
            )
        })
    }

    /// Shows the two step login alert. If `Yes` is selected, the user will be navigated to the web app.
    private func showTwoStepLoginAlert() {
        coordinator.showAlert(.twoStepLoginAlert {
            self.state.twoStepLoginUrl = self.services.twoStepLoginService.twoStepLoginUrl()
        })
    }

    /// Sets the user's biometric auth
    ///
    /// - Parameter enabled: Whether or not the the user wants biometric auth enabled.
    ///
    private func setBioMetricAuth(_ enabled: Bool) async {
        do {
            try await services.authRepository.allowBioMetricUnlock(enabled)
            state.biometricUnlockStatus = try await services.biometricsRepository.getBiometricUnlockStatus()
            // Set biometric integrity if needed.
            if case .available(_, true, false) = state.biometricUnlockStatus {
                try await services.biometricsRepository.configureBiometricIntegrity()
                state.biometricUnlockStatus = try await services.biometricsRepository.getBiometricUnlockStatus()
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Sets the user's pin.
    ///
    /// - Parameters:
    ///   - pin: The user's pin.
    ///   - requirePasswordAfterRestart: Whether the user's master password should be required after
    ///     an app restart.
    ///
    private func setPin(_ pin: String, requirePasswordAfterRestart: Bool) async {
        do {
            try await services.authRepository.setPins(
                pin,
                requirePasswordAfterRestart: requirePasswordAfterRestart
            )
            state.isUnlockWithPINCodeOn = true
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(
                title: Localizations.anErrorHasOccurred
            ))
        }
    }

    /// Shows an alert prompting the user to enter their PIN. If set successfully, the toggle will be turned on.
    ///
    /// - Parameter isOn: Whether or not the toggle value is true or false.
    ///
    private func toggleUnlockWithPIN(_ isOn: Bool) {
        if isOn {
            coordinator.showAlert(.enterPINCode(completion: { pin in
                do {
                    let userHasMasterPassword = try await self.services.stateService.getUserHasMasterPassword()
                    if userHasMasterPassword {
                        self.coordinator.showAlert(.unlockWithPINCodeAlert { requirePassword in
                            await self.setPin(pin, requirePasswordAfterRestart: requirePassword)
                        })
                    } else {
                        await self.setPin(pin, requirePasswordAfterRestart: false)
                    }
                } catch {
                    self.services.errorReporter.log(error: error)
                    self.coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
                }
            }))
        } else {
            Task {
                do {
                    try await self.services.authRepository.clearPins()
                    state.isUnlockWithPINCodeOn = isOn
                } catch {
                    self.coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
                }
            }
        }
    }
}
