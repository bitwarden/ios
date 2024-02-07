import Foundation

// MARK: - ProfileSwitcherHandler

protocol ProfileSwitcherHandler: AnyObject {
    typealias ProfileServices = HasAuthRepository
        & HasErrorReporter

    /// The `State` for the profile switcher.
    var profileSwitcherState: ProfileSwitcherState { get set }

    /// The services used by this handler.
    var profileServices: ProfileServices { get }

    /// The `State` for a toast view.
    var toast: Toast? { get set }

    /// Handles auth events that require asynchronous management.
    ///
    /// - Parameter authEvent: The auth event to handle.
    ///
    func handleAuthEvent(_ authEvent: AuthEvent) async

    /// Handles a profile switcher action.
    ///
    /// - Parameter action: The action to handle.
    ///
    @MainActor
    func handleProfileSwitcherAction(_ action: ProfileSwitcherAction)

    /// Handles a profile switcher action.
    ///
    /// - Parameter effect: The effect to handle.
    ///
    @MainActor
    func handleProfileSwitcherEffect(_ effect: ProfileSwitcherEffect) async

    /// Configures a profile switcher state with the current account and alternates.
    ///
    func refreshProfileState() async

    /// A function to determine if this handler should hide add account.
    ///
    /// - Returns: should add account be hidden?
    ///
    func shouldHideAddAccount() -> Bool

    /// Shows the correct destination for add account.
    ///
    func showAddAccount()

    /// Shows the provided alert on the `stackNavigator`.
    ///
    /// - Parameter alert: The alert to show.
    ///
    func showAlert(_ alert: Alert)
}

extension ProfileSwitcherHandler {
    @MainActor
    func handleProfileSwitcherAction(_ action: ProfileSwitcherAction) {
        switch action {
        case let .accessibility(accessibilityAction):
            switch accessibilityAction {
            case let .logout(account):
                confirmLogout(account)
            }
        case .backgroundPressed:
            profileSwitcherState.isVisible = false
        case let .requestedProfileSwitcher(visible: isVisible):
            profileSwitcherState.isVisible = isVisible
        case let .scrollOffsetChanged(newOffset):
            profileSwitcherState.scrollOffset = newOffset
        }
    }

    func handleProfileSwitcherEffect(_ effect: ProfileSwitcherEffect) async {
        switch effect {
        case let .accessibility(accessibility):
            switch accessibility {
            case let .lock(account):
                await lock(account)
            case let .select(account):
                await select(account)
            }
        case let .accountLongPressed(account):
            await didLongPressProfileSwitcherItem(account)
        case let .accountPressed(account):
            await select(account)
        case .addAccountPressed:
            profileSwitcherState.isVisible = false
            showAddAccount()
        case let .rowAppeared(rowType):
            await rowAppeared(rowType)
        }
    }

    func refreshProfileState() async {
        profileSwitcherState = await profileServices.authRepository.getProfilesState(
            isVisible: profileSwitcherState.isVisible,
            shouldAlwaysHideAddAccount: shouldHideAddAccount()
        )
    }
}

private extension ProfileSwitcherHandler {
    /// Confirms that the user would like to log out of an account by presenting an alert.
    ///
    /// - Parameter account: The profile switcher item for the account to be logged out.
    ///
    @MainActor
    func confirmLogout(_ account: ProfileSwitcherItem) {
        // Confirm logging out.
        showAlert(.logoutConfirmation { [weak self] in
            guard let self else { return }
            await logout(account)
        })
    }

    /// Handles a long press of an account in the profile switcher.
    ///
    /// - Parameter account: The `ProfileSwitcherItem` long pressed by the user.
    ///
    @MainActor
    func didLongPressProfileSwitcherItem(_ account: ProfileSwitcherItem) async {
        profileSwitcherState.isVisible = false
        let hasNeverLock = await (try? profileServices.authRepository
            .sessionTimeoutValue(userId: account.userId))
            == SessionTimeoutValue.never
        showAlert(
            .accountOptions(
                account,
                hasNeverLock: hasNeverLock,
                lockAction: {
                    await self.lock(account)
                },
                logoutAction: {
                    self.confirmLogout(account)
                }
            )
        )
    }

    func lock(_ account: ProfileSwitcherItem) async {
        do {
            // Lock the vault of the selected account.
            let activeAccountId = try await profileServices.authRepository.getUserId()
            await handleAuthEvent(.action(.lockVault(userId: account.userId)))

            // No navigation is necessary, since the user is already on the unlock
            // vault view, but if it was the non-active account, display a success toast
            // and update the profile switcher view.
            if account.userId != activeAccountId {
                toast = Toast(text: Localizations.accountLockedSuccessfully)
                await refreshProfileState()
            }
        } catch {
            profileServices.errorReporter.log(error: error)
        }
    }

    /// Log out of an account.
    ///
    /// - Parameter account: The profile switcher item for the account to be logged out.
    ///
    func logout(_ account: ProfileSwitcherItem) async {
        do {
            // Log out of the selected account.
            let activeAccountId = try await profileServices.authRepository.getUserId()
            await handleAuthEvent(.action(.logout(userId: account.userId, userInitiated: true)))

            // If that account was not active,
            // show a toast that the account was logged out successfully.
            if account.userId != activeAccountId {
                toast = Toast(text: Localizations.accountLoggedOutSuccessfully)

                // Update the profile switcher view.
                await refreshProfileState()
            }
        } catch {
            profileServices.errorReporter.log(error: error)
        }
    }

    /// A profile switcher row appeared.
    ///
    /// - Parameter rowType: The row type that appeared.
    ///
    func rowAppeared(_ rowType: ProfileSwitcherRowState.RowType) async {
        guard profileSwitcherState.shouldSetAccessibilityFocus(for: rowType) == true else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.profileSwitcherState.hasSetAccessibilityFocus = true
        }
    }

    /// Select an account to become active.
    ///
    /// - Parameter account: The profile switcher item for the account to activate.
    ///
    func select(_ account: ProfileSwitcherItem) async {
        defer { profileSwitcherState.isVisible = false }
        guard account.userId != profileSwitcherState.activeAccountId else { return }
        await handleAuthEvent(
            .action(
                .switchAccount(
                    isAutomatic: false,
                    userId: account.userId
                )
            )
        )
    }
}
