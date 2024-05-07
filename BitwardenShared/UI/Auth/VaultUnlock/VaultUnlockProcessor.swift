import OSLog

/// The processor used to manage state and handle actions for the vault unlock screen.
///
class VaultUnlockProcessor: StateProcessor<
    VaultUnlockState,
    VaultUnlockAction,
    VaultUnlockEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasBiometricsRepository
        & HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// A flag indicating if the processor should attempt automatic biometric unlock
    var shouldAttemptAutomaticBiometricUnlock = false

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `VaultUnlockProcessor`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: VaultUnlockState
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultUnlockEffect) async {
        switch effect {
        case .appeared:
            await refreshProfileState()
            await checkIfPinUnlockIsAvailable()
            await loadData()
        case let .profileSwitcher(profileEffect):
            await handleProfileSwitcherEffect(profileEffect)
        case .unlockVault:
            await showExtensionKdfMemoryWarningIfNecessary {
                await self.unlockVault()
            }
        case .unlockVaultWithBiometrics:
            await showExtensionKdfMemoryWarningIfNecessary {
                await self.unlockWithBiometrics()
            }
        }
    }

    override func receive(_ action: VaultUnlockAction) {
        switch action {
        case .cancelPressed:
            appExtensionDelegate?.didCancel()
        case let .masterPasswordChanged(masterPassword):
            state.masterPassword = masterPassword
        case .morePressed:
            let alert = Alert(
                title: Localizations.options,
                message: nil,
                preferredStyle: .actionSheet,
                alertActions: [
                    AlertAction(title: Localizations.logOut, style: .default) { _ in
                        self.showLogoutConfirmation()
                    },
                    AlertAction(title: Localizations.cancel, style: .cancel),
                ]
            )
            coordinator.showAlert(alert)
        case let .pinChanged(pin):
            state.pin = pin
        case let .profileSwitcher(profileAction):
            handleProfileSwitcherAction(profileAction)
        case let .revealMasterPasswordFieldPressed(isMasterPasswordRevealed):
            state.isMasterPasswordRevealed = isMasterPasswordRevealed
        case let .revealPinFieldPressed(isPinRevealed):
            state.isPinRevealed = isPinRevealed
        case let .toastShown(toast):
            state.toast = toast
        }
    }

    // MARK: Private

    /// Checks whether or not pin unlock is available.
    ///
    private func checkIfPinUnlockIsAvailable() async {
        do {
            if try await services.authRepository.isPinUnlockAvailable() {
                state.unlockMethod = .pin
            } else if try await services.stateService.getEncryptedPin() != nil {
                state.unlockMethod = .password
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Loads the async state data for the view
    ///
    private func loadData() async {
        state.biometricUnlockStatus = await (try? services.biometricsRepository.getBiometricUnlockStatus())
            ?? .notAvailable
        state.unsuccessfulUnlockAttemptsCount = await services.stateService.getUnsuccessfulUnlockAttempts()
        state.isInAppExtension = appExtensionDelegate?.isInAppExtension ?? false
        await refreshProfileState()
        // If biometric unlock is available, enabled,
        // and the user's biometric integrity state is valid;
        // attempt to unlock the vault with biometrics once.
        if case .available(_, true, true) = state.biometricUnlockStatus,
           shouldAttemptAutomaticBiometricUnlock {
            shouldAttemptAutomaticBiometricUnlock = false
            await unlockWithBiometrics()
        }
    }

    /// Log out the present user.
    ///
    /// - Parameters:
    ///   - resetAttempts: A Bool indicating if the the login attempts counter should be reset.
    ///   - userInitiated: A Bool indicating if the logout is initiated by a user action.
    ///
    private func logoutUser(resetAttempts: Bool = false, userInitiated: Bool) async {
        if resetAttempts {
            state.unsuccessfulUnlockAttemptsCount = 0
            await services.stateService.setUnsuccessfulUnlockAttempts(0)
        }
        await coordinator.handleEvent(
            .action(
                .logout(
                    userId: nil,
                    userInitiated: userInitiated
                )
            )
        )
    }

    /// Checks to see if the the extension KDF memory warning alert needs to be shown and shows it
    /// if necessary. The completion handler will be invoked if the alert doesn't need to be shown
    /// or if the user wants to continue despite the warning.
    ///
    /// - Parameter completion: A closure containing the action to take if the user wants to continue
    ///     with unlocking their vault despite the warning.
    ///
    private func showExtensionKdfMemoryWarningIfNecessary(completion: @escaping () async -> Void) async {
        guard appExtensionDelegate?.isInAppExtension == true,
              let account = try? await services.stateService.getActiveAccount(),
              account.profile.kdfType == .argon2id,
              let kdfMemory = account.profile.kdfMemory,
              kdfMemory > Constants.maxArgon2IdMemoryBeforeExtensionCrashing
        else {
            await completion()
            return
        }

        coordinator.showAlert(.extensionKdfMemoryWarning {
            await completion()
        })
    }

    /// Shows an alert asking the user to confirm that they want to logout.
    ///
    private func showLogoutConfirmation() {
        let alert = Alert.logoutConfirmation { [weak self] in
            guard let self else { return }
            await logoutUser(userInitiated: true)
        }
        coordinator.showAlert(alert)
    }

    /// Attempts to unlock the vault with the user's master password.
    ///
    private func unlockVault() async {
        do {
            switch state.unlockMethod {
            case .password:
                try EmptyInputValidator(fieldName: Localizations.masterPassword)
                    .validate(input: state.masterPassword)
                try await services.authRepository.unlockVaultWithPassword(password: state.masterPassword)
            case .pin:
                try EmptyInputValidator(fieldName: Localizations.pin)
                    .validate(input: state.pin)
                try await services.authRepository.unlockVaultWithPIN(pin: state.pin)
            }

            await coordinator.handleEvent(.didCompleteAuth)
            state.unsuccessfulUnlockAttemptsCount = 0
            await services.stateService.setUnsuccessfulUnlockAttempts(0)
        } catch let error as InputValidationError {
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
        } catch {
            let alert = Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: state.unlockMethod == .pin ? Localizations.invalidPIN : Localizations.invalidMasterPassword
            )
            Logger.processor.error("Error unlocking vault: \(error)")
            state.unsuccessfulUnlockAttemptsCount += 1
            await services.stateService.setUnsuccessfulUnlockAttempts(state.unsuccessfulUnlockAttemptsCount)
            if state.unsuccessfulUnlockAttemptsCount >= 5 {
                await logoutUser(resetAttempts: true, userInitiated: true)
                return
            }
            coordinator.showAlert(alert)
        }
    }

    /// Attempts to unlock the vault with the user's biometrics
    ///
    private func unlockWithBiometrics() async {
        let status = try? await services.biometricsRepository.getBiometricUnlockStatus()
        guard case let .available(_, enabled: enabled, hasValidIntegrity) = status,
              enabled,
              hasValidIntegrity else {
            await loadData()
            return
        }

        do {
            try await services.authRepository.unlockVaultWithBiometrics()
            await coordinator.handleEvent(.didCompleteAuth)
            state.unsuccessfulUnlockAttemptsCount = 0
            await services.stateService.setUnsuccessfulUnlockAttempts(0)
        } catch let error as BiometricsServiceError {
            Logger.processor.error("BiometricsServiceError unlocking vault with biometrics: \(error)")
            // If the user has locked biometry, logout immediately.
            if case .biometryLocked = error {
                await logoutUser(userInitiated: true)
                return
            }
            if case .biometryCancelled = error {
                // Do nothing if the user cancels.
                return
            }
            // There is no biometric auth key stored, set user preference to false.
            if case .getAuthKeyFailed = error {
                try? await services.authRepository.allowBioMetricUnlock(false)
            }
            await loadData()
        } catch let error as StateServiceError {
            // If there is no active account, don't add to the unsuccessful count.
            Logger.processor.error("StateServiceError unlocking vault with biometrics: \(error)")
            // Just send the user back to landing.
            coordinator.navigate(to: .landing)
        } catch {
            Logger.processor.error("Error unlocking vault with biometrics: \(error)")
            state.unsuccessfulUnlockAttemptsCount += 1
            await services.stateService
                .setUnsuccessfulUnlockAttempts(state.unsuccessfulUnlockAttemptsCount)
            if state.unsuccessfulUnlockAttemptsCount >= 5 {
                await logoutUser(resetAttempts: true, userInitiated: true)
                return
            }
            await loadData()
        }
    }
}

// MARK: - ProfileSwitcherHandler

extension VaultUnlockProcessor: ProfileSwitcherHandler {
    var allowLockAndLogout: Bool {
        true
    }

    var profileServices: ProfileServices {
        services
    }

    var profileSwitcherState: ProfileSwitcherState {
        get {
            state.profileSwitcherState
        }
        set {
            state.profileSwitcherState = newValue
        }
    }

    var shouldHideAddAccount: Bool {
        appExtensionDelegate?.isInAppExtension ?? false
    }

    var toast: Toast? {
        get {
            state.toast
        }
        set {
            state.toast = newValue
        }
    }

    func handleAuthEvent(_ authEvent: AuthEvent) async {
        await coordinator.handleEvent(authEvent)
    }

    func showAddAccount() {
        coordinator.navigate(to: .landing)
    }

    func showAlert(_ alert: Alert) {
        coordinator.showAlert(alert)
    }
}
