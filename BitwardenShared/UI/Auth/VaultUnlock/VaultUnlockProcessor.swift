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
        case let .toastShown(toast):
            state.toast = toast
        }
    }

    // MARK: Private

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
            try EmptyInputValidator(fieldName: Localizations.masterPassword)
                .validate(input: state.masterPassword)

            try await services.authRepository.unlockVault(password: state.masterPassword)
            coordinator.navigate(to: .complete)
            state.unsuccessfulUnlockAttemptsCount = 0
            await services.stateService.setUnsuccessfulUnlockAttempts(0)
        } catch let error as InputValidationError {
            coordinator.navigate(to: .alert(Alert.inputValidationAlert(error: error)))
        } catch {
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
            coordinator.navigate(to: .alert(.invalidMasterPassword()))
        }
    }
}
