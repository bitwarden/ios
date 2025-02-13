import Foundation
import OSLog

// MARK: - AccountSecurityProcessor

/// The processor used to manage state and handle actions for the account security screen.
///
final class AccountSecurityProcessor: StateProcessor<// swiftlint:disable:this type_body_length
    AccountSecurityState,
    AccountSecurityAction,
    AccountSecurityEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasBiometricsRepository
        & HasConfigService
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

    /// A helper object to set up vault unlock methods.
    private let vaultUnlockSetupHelper: VaultUnlockSetupHelper

    // MARK: Initialization

    /// Creates a new `AccountSecurityProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///   - vaultUnlockSetupHelper: A helper object to set up vault unlock methods.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: AccountSecurityState,
        vaultUnlockSetupHelper: VaultUnlockSetupHelper
    ) {
        self.coordinator = coordinator
        self.services = services
        self.vaultUnlockSetupHelper = vaultUnlockSetupHelper
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AccountSecurityEffect) async {
        switch effect {
        case .accountFingerprintPhrasePressed:
            await showAccountFingerprintPhraseAlert()
        case .appeared:
            await appeared()
        case .dismissSetUpUnlockActionCard:
            await dismissSetUpUnlockActionCard()
        case .loadData:
            await loadData()
        case .lockVault:
            await coordinator.handleEvent(
                .authAction(
                    .lockVault(userId: nil, isManuallyLocking: true)
                )
            )
        case .streamSettingsBadge:
            await streamSettingsBadge()
        case let .toggleSyncWithAuthenticator(isOn):
            await setSyncToAuthenticator(isOn)
        case let .toggleUnlockWithBiometrics(isOn):
            await setBioMetricAuth(isOn)
        case let .toggleUnlockWithPINCode(isOn):
            await toggleUnlockWithPIN(isOn)
        }
    }

    override func receive(_ action: AccountSecurityAction) {
        switch action {
        case .clearFingerprintPhraseUrl:
            state.fingerprintPhraseUrl = nil
        case .clearTwoStepLoginUrl:
            state.twoStepLoginUrl = nil
        case let .customTimeoutValueSecondsChanged(seconds):
            setVaultTimeout(value: .custom(seconds / 60))
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
        case .showSetUpUnlock:
            coordinator.navigate(to: .vaultUnlockSetup)
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
                state.policyTimeoutAction = policy.action

                state.policyTimeoutValue = policy.value
                state.isTimeoutPolicyEnabled = true
            }

            state.hasMasterPassword = try await services.stateService.getUserHasMasterPassword()
            state.sessionTimeoutValue = try await services.stateService.getVaultTimeout()
            state.sessionTimeoutAction = try await services.authRepository.sessionTimeoutAction()
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// If the native create account feature flag is enabled, this marks the user's vault unlock
    /// account setup complete. This should be called whenever PIN or biometrics unlock has been
    /// turned on.
    ///
    private func completeAccountSetupVaultUnlockIfNeeded() async {
        guard await services.configService.getFeatureFlag(.nativeCreateAccountFlow) else { return }
        do {
            guard let progress = try await services.stateService.getAccountSetupVaultUnlock(),
                  progress != .complete
            else { return }
            try await services.stateService.setAccountSetupVaultUnlock(.complete)
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Dismisses the set up unlock action card by marking the user's vault unlock setup progress complete.
    ///
    private func dismissSetUpUnlockActionCard() async {
        do {
            try await services.stateService.setAccountSetupVaultUnlock(.complete)
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    /// Load any initial data for the view.
    private func loadData() async {
        do {
            state.removeUnlockWithPinPolicyEnabled = await services.policyService.policyAppliesToUser(
                .removeUnlockWithPin
            )

            state.biometricUnlockStatus = await loadBiometricUnlockPreference()

            if try await services.authRepository.isPinUnlockAvailable() {
                state.isUnlockWithPINCodeOn = true
            }
            state.shouldShowAuthenticatorSyncSection =
                await services.configService.getFeatureFlag(.enableAuthenticatorSync)
            if state.shouldShowAuthenticatorSyncSection {
                state.isAuthenticatorSyncEnabled = try await services.stateService.getSyncToAuthenticator()
            }

            if state.biometricUnlockStatus.isEnabled || state.isUnlockWithPINCodeOn {
                await completeAccountSetupVaultUnlockIfNeeded()
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

    /// Refreshes the vault timeout action in case the user doesn't have a password.
    ///
    /// This should be called whenever biometrics or pin unlock are disabled to ensure the timeout
    /// action is updated in the event that the user doesn't have a password.
    ///
    private func refreshVaultTimeoutAction() async {
        if let sessionTimeoutAction = try? await services.authRepository.sessionTimeoutAction() {
            state.sessionTimeoutAction = sessionTimeoutAction
        }
    }

    /// Sets the user's sync with Authenticator setting
    ///
    /// - Parameter enabled: Whether or not the the user wants to enable sync with Authenticator.
    ///
    private func setSyncToAuthenticator(_ enabled: Bool) async {
        do {
            try await services.stateService.setSyncToAuthenticator(enabled)
            state.isAuthenticatorSyncEnabled = enabled
        } catch {
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
        let biometricUnlockStatus = await vaultUnlockSetupHelper.setBiometricUnlock(
            enabled: enabled,
            showAlert: coordinator.showAlert
        )
        state.biometricUnlockStatus = biometricUnlockStatus ?? .notAvailable

        // Refresh vault timeout action in case the user doesn't have a password and biometric
        // unlock was disabled.
        await refreshVaultTimeoutAction()

        if enabled {
            await completeAccountSetupVaultUnlockIfNeeded()
        }
    }

    /// Streams the state of the badges in the settings tab.
    ///
    private func streamSettingsBadge() async {
        guard await services.configService.getFeatureFlag(.nativeCreateAccountFlow) else { return }
        do {
            for await badgeState in try await services.stateService.settingsBadgePublisher().values {
                state.badgeState = badgeState
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Shows an alert prompting the user to enter their PIN. If set successfully, the toggle will be turned on.
    ///
    /// - Parameter isOn: Whether or not the toggle value is true or false.
    ///
    private func toggleUnlockWithPIN(_ isOn: Bool) async {
        state.isUnlockWithPINCodeOn = await vaultUnlockSetupHelper.setPinUnlock(
            enabled: isOn,
            showAlert: coordinator.showAlert
        )

        // Refresh vault timeout action in case the user doesn't have a password and the pin was disabled.
        await refreshVaultTimeoutAction()

        if isOn {
            await completeAccountSetupVaultUnlockIfNeeded()
        }
    }
}
