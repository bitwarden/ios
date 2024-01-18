import OSLog

/// The processor used to manage state and handle actions for the vault unlock screen.
///
class VaultUnlockProcessor: StateProcessor<VaultUnlockState, VaultUnlockAction, VaultUnlockEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthRoute>

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
            await setPins()
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
        }
    }

    // MARK: Private

    private func checkIfPinUnlockIsAvailable() async {
        do {
            if try await services.authRepository.isPinUnlockAvailable() {
                state.unlockMethod = .pin
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Shows an alert asking the user to confirm that they want to logout.
    ///
    private func showLogoutConfirmation() {
        let alert = Alert.logoutConfirmation {
            do {
                try await self.services.authRepository.logout()
            } catch {
                self.services.errorReporter.log(error: BitwardenError.logoutError(error: error))
            }
            self.coordinator.navigate(to: .landing)
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

    /// Handles a tap of an account in the profile switcher
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

    /// Sets the user's pins if a pin protected user key exists.
    ///
    private func setPins() async {
        do {
            if let pin = try await services.stateService.pinProtectedUserKey() {
                try await services.authRepository.setPins(pin, requirePasswordAfterRestart: true)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
