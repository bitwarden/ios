import OSLog

/// The processor used to manage state and handle actions for the vault unlock screen.
///
class VaultUnlockProcessor: StateProcessor<VaultUnlockState, VaultUnlockAction, VaultUnlockEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `VaultUnlockProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        services: Services,
        state: VaultUnlockState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultUnlockEffect) async {
        switch effect {
        case .appeared:
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
        }
    }

    // MARK: Private

    /// Shows an alert asking the user to confirm that they want to logout.
    ///
    private func showLogoutConfirmation() {
        let alert = Alert.logoutConfirmation {
            do {
                try await self.services.authRepository.logout(
                    userId: self.state.profileSwitcherState.activeAccountId,
                    state: self.state.profileSwitcherState
                )
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

            try await services.authRepository.unlockVault(
                password: state.masterPassword,
                state: state.profileSwitcherState
            )
            coordinator.navigate(to: .complete)
        } catch let error as InputValidationError {
            coordinator.navigate(to: .alert(Alert.inputValidationAlert(error: error)))
        } catch {
            let alert = Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.invalidMasterPassword
            )
            coordinator.navigate(to: .alert(alert))
            Logger.processor.error("Error unlocking vault: \(error)")
        }
    }

    /// Handles a tap of an account in the profile switcher
    /// - Parameter selectedAccount: The `ProfileSwitcherItem` selected by the user.
    ///
    private func didTapProfileSwitcherItem(_ selectedAccount: ProfileSwitcherItem) {
        defer { state.profileSwitcherState.isVisible = false }
        guard selectedAccount.userId != state.profileSwitcherState.activeAccountId else { return }
        Task {
            do {
                if let newState = try await services.authRepository.setActiveAccount(
                    userId: selectedAccount.userId,
                    state: state.profileSwitcherState
                ) {
                    state.profileSwitcherState = newState
                }
                let account = try await services.authRepository.getAccount(for: selectedAccount.userId)
                didTapAccount(account, isUnlocked: selectedAccount.isUnlocked)
            } catch {
                services.errorReporter.log(error: error)
            }
        }
    }

    /// Handles a tap of an account.
    /// - Parameters
    ///   - account: The selected account.
    ///   - isUnlocked: The last known lock state of an account.
    ///
    private func didTapAccount(_ account: Account, isUnlocked: Bool) {
        if isUnlocked {
            coordinator.navigate(to: .complete)
        } else {
            coordinator.navigate(to: .vaultUnlock(account))
        }
    }

    /// Configures a profile switcher state with the current account and alternates.
    ///
    private func refreshProfileState() async {
        state.profileSwitcherState = await services.authRepository.getProfileSwitcherState(
            visible: state.profileSwitcherState.isVisible,
            shouldAlwaysHideAddAccount: false
        )
    }
}
