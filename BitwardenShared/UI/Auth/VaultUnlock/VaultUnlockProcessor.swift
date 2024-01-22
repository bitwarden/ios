import OSLog

/// The processor used to manage state and handle actions for the vault unlock screen.
///
class VaultUnlockProcessor: StateProcessor<VaultUnlockState, VaultUnlockAction, VaultUnlockEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasBiometricsService
        & HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthRoute>

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
        coordinator: AnyCoordinator<AuthRoute>,
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
            state.isInAppExtension = appExtensionDelegate?.isInAppExtension ?? false
            state.unsuccessfulUnlockAttemptsCount = await services.stateService.getUnsuccessfulUnlockAttempts()
            await refreshProfileState()
            await checkIfPinUnlockIsAvailable()
            await loadData()
        case let .profileSwitcher(profileEffect):
            switch profileEffect {
            case let .rowAppeared(rowType):
                guard state.profileSwitcherState.shouldSetAccessibilityFocus(for: rowType) == true else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.state.profileSwitcherState.hasSetAccessibilityFocus = true
                }
            }
        case .unlockVault:
            await unlockVault()
        case .unlockVaultWithBiometrics:
            await unlockWithBiometrics()
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
            coordinator.navigate(to: .alert(alert))
        case let .pinChanged(pin):
            state.pin = pin
        case let .profileSwitcherAction(profileAction):
            switch profileAction {
            case let .accountLongPressed(account):
                didLongPressProfileSwitcherItem(account)
            case let .accountPressed(account):
                didTapProfileSwitcherItem(account)
            case .addAccountPressed:
                state.profileSwitcherState.isVisible = false
                coordinator.navigate(to: .landing)
            case .backgroundPressed:
                state.profileSwitcherState.isVisible = false
            case let .requestedProfileSwitcher(visible: isVisible):
                state.profileSwitcherState.isVisible = isVisible
            case let .scrollOffsetChanged(newOffset):
                state.profileSwitcherState.scrollOffset = newOffset
            }
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
            } else if try await services.stateService.pinKeyEncryptedUserKey() != nil {
                state.unlockMethod = .password
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Loads the async state data for the view
    ///
    private func loadData() async {
        state.biometricUnlockStatus = await (try? services.biometricsService.getBiometricUnlockStatus())
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
    private func logoutUser(resetAttempts: Bool = false) async {
        do {
            if resetAttempts {
                state.unsuccessfulUnlockAttemptsCount = 0
                await services.stateService.setUnsuccessfulUnlockAttempts(0)
            }
            try await services.authRepository.logout()
        } catch {
            services.errorReporter.log(error: BitwardenError.logoutError(error: error))
        }
        coordinator.navigate(to: .landing)
    }

    /// Handles a long press of an account in the profile switcher.
    ///
    /// - Parameter account: The `ProfileSwitcherItem` long pressed by the user.
    ///
    private func didLongPressProfileSwitcherItem(_ account: ProfileSwitcherItem) {
        state.profileSwitcherState.isVisible = false
        coordinator.showAlert(.accountOptions(account, lockAction: {
            do {
                // Lock the vault of the selected account.
                let activeAccountId = try await self.services.authRepository.getActiveAccount().userId
                await self.services.authRepository.lockVault(userId: account.userId)

                // No navigation is necessary, since the user is already on the unlock
                // vault view, but if it was the non-active account, display a success toast
                // and update the profile switcher view.
                if account.userId != activeAccountId {
                    self.state.toast = Toast(text: Localizations.accountLockedSuccessfully)
                    await self.refreshProfileState()
                }
            } catch {
                self.services.errorReporter.log(error: error)
            }
        }, logoutAction: {
            // Confirm logging out.
            self.coordinator.showAlert(.logoutConfirmation {
                do {
                    // Log out of the selected account.
                    let activeAccountId = try await self.services.authRepository.getActiveAccount().userId
                    try await self.services.authRepository.logout(userId: account.userId)

                    // If the selected item was the currently active account, redirect the user
                    // to the landing page.
                    if account.userId == activeAccountId {
                        self.coordinator.navigate(to: .landing)
                    } else {
                        // Otherwise, show the toast that the account was logged out successfully.
                        self.state.toast = Toast(text: Localizations.accountLoggedOutSuccessfully)

                        // Update the profile switcher view.
                        await self.refreshProfileState()
                    }
                } catch {
                    self.services.errorReporter.log(error: error)
                }
            })
        }))
    }

    /// Handles a tap of an account in the profile switcher.
    ///
    /// - Parameter selectedAccount: The `ProfileSwitcherItem` selected by the user.
    ///
    private func didTapProfileSwitcherItem(_ selectedAccount: ProfileSwitcherItem) {
        coordinator.navigate(to: .switchAccount(userId: selectedAccount.userId))
        state.profileSwitcherState.isVisible = false
    }

    /// Configures a profile switcher state with the current account and alternates.
    ///
    private func refreshProfileState() async {
        var accounts = [ProfileSwitcherItem]()
        var activeAccount: ProfileSwitcherItem?
        do {
            accounts = try await services.authRepository.getAccounts()
            guard !accounts.isEmpty else { return }
            activeAccount = try? await services.authRepository.getActiveAccount()
            state.profileSwitcherState = ProfileSwitcherState(
                accounts: accounts,
                activeAccountId: activeAccount?.userId,
                isVisible: state.profileSwitcherState.isVisible,
                shouldAlwaysHideAddAccount: appExtensionDelegate?.isInAppExtension ?? false
            )
        } catch {
            state.profileSwitcherState = .empty()
        }
    }

    /// Shows an alert asking the user to confirm that they want to logout.
    ///
    private func showLogoutConfirmation() {
        let alert = Alert.logoutConfirmation { [weak self] in
            guard let self else { return }
            await logoutUser()
        }
        coordinator.navigate(to: .alert(alert))
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

            coordinator.navigate(to: .complete)
            state.unsuccessfulUnlockAttemptsCount = 0
            await services.stateService.setUnsuccessfulUnlockAttempts(0)
        } catch let error as InputValidationError {
            coordinator.navigate(to: .alert(Alert.inputValidationAlert(error: error)))
        } catch {
            let alert = Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: state.unlockMethod == .pin ? Localizations.invalidPIN : Localizations.invalidMasterPassword
            )
            Logger.processor.error("Error unlocking vault: \(error)")
            state.unsuccessfulUnlockAttemptsCount += 1
            await services.stateService.setUnsuccessfulUnlockAttempts(state.unsuccessfulUnlockAttemptsCount)
            if state.unsuccessfulUnlockAttemptsCount >= 5 {
                do {
                    state.unsuccessfulUnlockAttemptsCount = 0
                    await services.stateService.setUnsuccessfulUnlockAttempts(0)
                    try await services.authRepository.logout()
                } catch {
                    services.errorReporter.log(error: BitwardenError.logoutError(error: error))
                }
                coordinator.navigate(to: .landing)
                return
            }
            coordinator.navigate(to: .alert(alert))
        }
    }

    /// Attempts to unlock the vault with the user's biometrics
    ///
    private func unlockWithBiometrics() async {
        let status = try? await services.biometricsService.getBiometricUnlockStatus()
        guard case let .available(_, enabled: enabled, hasValidIntegrity) = status,
              enabled,
              hasValidIntegrity else {
            await loadData()
            return
        }

        do {
            try await services.authRepository.unlockVaultWithBiometrics()
            coordinator.navigate(to: .complete)
            state.unsuccessfulUnlockAttemptsCount = 0
            await services.stateService.setUnsuccessfulUnlockAttempts(0)
        } catch let error as BiometricsServiceError {
            Logger.processor.error("BiometricsServiceError unlocking vault with biometrics: \(error)")
            // If the user has locked biometry, logout immediately.
            if case .biometryLocked = error {
                await logoutUser()
                return
            }
            // There is no biometric auth key stored, set user preference to false.
            if case .getAuthKeyFailed = error {
                try? await services.authRepository.allowBioMetricUnlock(false, userId: nil)
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
                await logoutUser(resetAttempts: true)
                return
            }
            await loadData()
        }
    }
} // swiftlint:disable:this file_length
