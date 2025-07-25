import BitwardenResources
import Foundation

// MARK: - ProfileSwitcherHandler

/// A protocol for a `@MainActor` object that handles ProfileSwitcherView Actions & Effects.
///     Most likely, this will be a processor.
///
@MainActor
protocol ProfileSwitcherHandler: AnyObject {
    typealias ProfileServices = HasAuthRepository
        & HasErrorReporter

    /// Should the view allow lock & logout?
    var allowLockAndLogout: Bool { get }

    /// The `State` for the profile switcher.
    var profileSwitcherState: ProfileSwitcherState { get set }

    /// The services used by this handler.
    var profileServices: ProfileServices { get }

    /// Should this handler should hide add account?
    var shouldHideAddAccount: Bool { get }

    /// Should the handler replace the toolbar icon with two dots?
    var showPlaceholderToolbarIcon: Bool { get }

    /// The route that should be navigated to after switching accounts and vault unlock.
    var switchAccountAuthCompletionRoute: AppRoute? { get }

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
    func handleProfileSwitcherAction(_ action: ProfileSwitcherAction)

    /// Handles a profile switcher action.
    ///
    /// - Parameter effect: The effect to handle.
    ///
    func handleProfileSwitcherEffect(_ effect: ProfileSwitcherEffect) async

    /// Configures a profile switcher state with the current account and alternates.
    ///
    func refreshProfileState() async

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
    /// Default to non-placeholder switcher icon.
    var showPlaceholderToolbarIcon: Bool {
        false
    }

    /// Default the auth completion route after switching accounts to `nil` to navigate to the vault list.
    var switchAccountAuthCompletionRoute: AppRoute? {
        nil
    }

    func handleProfileSwitcherAction(_ action: ProfileSwitcherAction) {
        switch action {
        case let .accessibility(accessibilityAction):
            switch accessibilityAction {
            case let .logout(account):
                confirmLogout(account)
            case let .remove(account):
                confirmRemoveAccount(account)
            }
        case .backgroundPressed:
            profileSwitcherState.isVisible = false
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
        case let .requestedProfileSwitcher(isVisible):
            if isVisible {
                await profileServices.authRepository.checkSessionTimeouts(handleActiveUser: nil)
                await refreshProfileState()
            }
            profileSwitcherState.isVisible = isVisible
        case let .rowAppeared(rowType):
            await rowAppeared(rowType)
        }
    }

    func refreshProfileState() async {
        profileSwitcherState = await profileServices.authRepository.getProfilesState(
            allowLockAndLogout: allowLockAndLogout,
            isVisible: profileSwitcherState.isVisible,
            shouldAlwaysHideAddAccount: shouldHideAddAccount,
            showPlaceholderToolbarIcon: showPlaceholderToolbarIcon
        )
    }
}

private extension ProfileSwitcherHandler {
    /// Confirms that the user would like to log out of an account by presenting an alert.
    ///
    /// - Parameter profile: The profile switcher item for the account to be logged out.
    ///
    func confirmLogout(_ profile: ProfileSwitcherItem) {
        // Confirm logging out.
        showAlert(
            .logoutConfirmation(profile) { [weak self] in
                guard let self else { return }
                await logout(profile)
            }
        )
    }

    /// Confirms that the user would like to log out of an account by presenting an alert.
    ///
    /// - Parameter profile: The profile switcher item for the account to be logged out.
    ///
    func confirmRemoveAccount(_ profile: ProfileSwitcherItem) {
        showAlert(
            .removeAccountConfirmation(profile) { [weak self] in
                guard let self else { return }
                await removeAccount(profile)
            }
        )
    }

    /// Handles a long press of an account in the profile switcher.
    ///
    /// - Parameter account: The `ProfileSwitcherItem` long pressed by the user.
    ///
    func didLongPressProfileSwitcherItem(_ account: ProfileSwitcherItem) async {
        profileSwitcherState.isVisible = false
        showAlert(
            .accountOptions(
                account,
                lockAction: {
                    await self.lock(account)
                },
                logoutAction: {
                    self.confirmLogout(account)
                },
                removeAccountAction: {
                    self.confirmRemoveAccount(account)
                }
            )
        )
    }

    /// Lock an account.
    ///
    /// - Parameter account: The profile switcher item for the account to lock.
    ///
    func lock(_ account: ProfileSwitcherItem) async {
        do {
            // Lock the vault of the selected account.
            let activeAccountId = try await profileServices.authRepository.getUserId()
            await handleAuthEvent(.action(.lockVault(userId: account.userId, isManuallyLocking: true)))

            // No navigation is necessary, since the user is already on the unlock
            // vault view, but if it was the non-active account, display a success toast
            // and update the profile switcher view.
            if account.userId != activeAccountId {
                toast = Toast(title: Localizations.accountLockedSuccessfully)
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
                toast = Toast(title: Localizations.accountLoggedOutSuccessfully)

                // Update the profile switcher view.
                await refreshProfileState()
            }
        } catch {
            profileServices.errorReporter.log(error: error)
        }
    }

    /// Remove an account.
    ///
    /// - Parameter account: The profile switcher item for the account to be removed.
    ///
    func removeAccount(_ account: ProfileSwitcherItem) async {
        do {
            let activeAccountId = try await profileServices.authRepository.getUserId()

            if account.userId == activeAccountId {
                // If the active account is being removed, forward it to the router to handle
                // removing the account and any navigation associated with it (e.g. switch to next
                // active account).
                // A user-initiated logout functions the same as removing the account.
                await handleAuthEvent(.action(.logout(userId: account.userId, userInitiated: true)))
            } else {
                // Otherwise, if it's an inactive account, it can be removed directly.
                // A user-initiated logout functions the same as removing the account.
                try await profileServices.authRepository.logout(userId: account.userId, userInitiated: true)
                toast = Toast(title: Localizations.accountRemovedSuccessfully)

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
        guard account.userId != profileSwitcherState.activeAccountId || showPlaceholderToolbarIcon else { return }
        await handleAuthEvent(
            .action(
                .switchAccount(
                    isAutomatic: false,
                    userId: account.userId,
                    authCompletionRoute: switchAccountAuthCompletionRoute
                )
            )
        )
    }
}
