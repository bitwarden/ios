// MARK: AuthRouterRedirects

// swiftlint:disable file_length

extension AuthRouter {
    /// Configures the app with an active account.
    ///
    /// - Parameter shouldSwitchAutomatically: Should the app switch to the next available account
    ///     if there is no active account?
    /// - Returns: The account model currently set as active.
    ///
    func configureActiveAccount(shouldSwitchAutomatically: Bool) async throws -> Account {
        if let active = try? await services.authRepository.getAccount() {
            return active
        }
        guard shouldSwitchAutomatically,
              let alternate = try await services.stateService.getAccounts().first else {
            throw StateServiceError.noActiveAccount
        }
        return try await services.authRepository.setActiveAccount(userId: alternate.profile.userId)
    }

    /// Handles the `didComplete` route by navigating the user to the update master password screen
    /// if their password needs to be updated or completes the auth flow by navigating the user to
    /// the vault.
    ///
    /// - Returns: A redirect route to either `.complete` or `.updateMasterPassword`.
    ///
    func completeAuthRedirect() async -> AuthRoute {
        guard let account = try? await services.authRepository.getAccount() else {
            return .landing
        }
        if account.profile.forcePasswordResetReason != nil {
            return .updateMasterPassword
        } else if await (try? services.stateService.getAccountSetupVaultUnlock()) == .incomplete {
            return .vaultUnlockSetup
            // TODO: PM-10278 Add autofill setup screen
//        } else if await (try? services.stateService.getAccountSetupAutofill()) == .incomplete {
//            return .autofillSetup
        } else {
            await setCarouselShownIfEnabled()
            return .complete
        }
    }

    /// Handles the `.didDeleteAccount`route and redirects the user to the correct screen
    ///     based on alternate accounts state. If the user has an alternate account,
    ///     they will go to the unlock sequence for that account.
    ///     Otherwise, the user will be directed to the landing screen.
    ///
    /// - Returns: A redirect to either `.landing` or `prepareAndRedirect(.vaultUnlock)`.
    ///
    func deleteAccountRedirect() async -> AuthRoute {
        // Ensure that the active account id is nil, otherwise, handle a failed account deletion by directing
        // The user to the unlock flow.
        let oldActiveId = try? await services.stateService.getActiveAccountId()
        // Try to set the next available account.
        guard let activeAccount = try? await configureActiveAccount(shouldSwitchAutomatically: true) else {
            // If no other accounts are available, go to landing.
            return .landing
        }
        // Setup the unlock route for the newly active account.
        let event = AuthEvent.accountBecameActive(
            activeAccount,
            animated: false,
            attemptAutomaticBiometricUnlock: true,
            didSwitchAccountAutomatically: oldActiveId != activeAccount.profile.userId
        )
        // Handle any vault unlock redirects for this active account.
        return await handleAndRoute(event)
    }

    /// Handles the `.didLogout()`route and redirects the user to the correct screen
    ///     based on whether the user initiated this logout. If the user initiated the logout has an alternate account,
    ///     they will be switched to the alternate and go to the unlock sequence for that account.
    ///     Otherwise, the user will be directed to the landing screen.
    ///
    ///     - Parameters:
    ///       - userId: The id of the user that was logged out.
    ///       - userInitiated: Did a user action initiate this logout?
    ///         If `true`, the app should attempt to switch to the next available account.
    ///     - Returns: A redirect to either `.landing` or `prepareAndRedirect(.vaultUnlock)`.
    ///
    func didLogoutRedirect(userId: String, userInitiated: Bool) async -> AuthRoute {
        // Try to get/set the available account. If `userInitiated`, attempt to switch to the next available account.
        guard let activeAccount = try? await configureActiveAccount(shouldSwitchAutomatically: userInitiated) else {
            return .landing
        }
        // Setup the unlock route for the newly active account.
        let event = AuthEvent.accountBecameActive(
            activeAccount,
            animated: false,
            attemptAutomaticBiometricUnlock: true,
            didSwitchAccountAutomatically: userId != activeAccount.profile.userId
        )
        // Handle any vault unlock redirects for this active account.
        return await handleAndRoute(event)
    }

    /// Handles the `.lockVault()`action and redirects the user to the correct screen.
    ///
    ///   - Parameter userId: The id of the user that should be locked.
    ///   - Returns: A redirect to either `.landing` or `prepareAndRedirect(.vaultUnlock)`.
    ///
    func lockVaultRedirect(userId: String?) async -> AuthRoute {
        let activeAccount = try? await services.authRepository.getAccount(for: nil)
        guard let accountToLock = try? await services.authRepository.getAccount(for: userId) else {
            if let activeAccount {
                return await handleAndRoute(
                    .accountBecameActive(
                        activeAccount,
                        animated: false,
                        attemptAutomaticBiometricUnlock: false,
                        didSwitchAccountAutomatically: false
                    )
                )
            } else {
                return .landing
            }
        }
        await services.authRepository.lockVault(userId: userId)
        guard let activeAccount else { return .landing }
        guard activeAccount.profile.userId == accountToLock.profile.userId else {
            return await handleAndRoute(
                .accountBecameActive(
                    activeAccount,
                    animated: false,
                    attemptAutomaticBiometricUnlock: false,
                    didSwitchAccountAutomatically: false
                )
            )
        }
        return await handleAndRoute(
            .didLockAccount(
                activeAccount,
                animated: false,
                attemptAutomaticBiometricUnlock: false,
                didSwitchAccountAutomatically: false
            )
        )
    }

    /// Handles the `.logout()` action and redirects the user to the correct screen.
    ///
    ///   - Parameter userId: The id of the user that should be logged out.
    ///   - Returns: A redirect to either `.landing` or `prepareAndRedirect(.vaultUnlock)`.
    ///
    func logoutRedirect( // swiftlint:disable:this function_body_length
        userId: String?,
        userInitiated: Bool
    ) async -> AuthRoute {
        let previouslyActiveAccount = try? await services.authRepository.getAccount(for: nil)
        guard let accountToLogOut = try? await services.authRepository.getAccount(for: userId) else {
            if let previouslyActiveAccount {
                return await handleAndRoute(
                    .accountBecameActive(
                        previouslyActiveAccount,
                        animated: false,
                        attemptAutomaticBiometricUnlock: false,
                        didSwitchAccountAutomatically: false
                    )
                )
            } else if userInitiated,
                      let accounts = try? await services.stateService.getAccounts(),
                      let next = accounts.first {
                return await switchAccountRedirect(isAutomatic: true, userId: next.profile.userId)
            } else {
                return .landing
            }
        }
        do {
            try await services.authRepository.logout(
                userId: accountToLogOut.profile.userId,
                userInitiated: userInitiated
            )
            if let previouslyActiveAccount,
               accountToLogOut.profile.userId != previouslyActiveAccount.profile.userId {
                return await handleAndRoute(
                    .accountBecameActive(
                        previouslyActiveAccount,
                        animated: false,
                        attemptAutomaticBiometricUnlock: false,
                        didSwitchAccountAutomatically: false
                    )
                )
            }
            if userInitiated,
               let accounts = try? await services.stateService.getAccounts(),
               let next = accounts.first {
                return await switchAccountRedirect(isAutomatic: true, userId: next.profile.userId)
            } else {
                return .landing
            }
        } catch {
            services.errorReporter.log(error: error)
            if let previouslyActiveAccount {
                return await handleAndRoute(
                    .accountBecameActive(
                        previouslyActiveAccount,
                        animated: false,
                        attemptAutomaticBiometricUnlock: true,
                        didSwitchAccountAutomatically: false
                    )
                )
            } else {
                return .landing
            }
        }
    }

    /// Handles the `.didStart`route and redirects the user to the correct screen based on active account state.
    ///
    ///   - Returns: A redirect to either `.landing`,  `prepareAndRedirect(.didTimeout())`,
    ///      or `prepareAndRedirect(.vaultUnlock())`.
    ///
    func preparedStartRoute() async -> AuthRoute {
        guard let activeAccount = try? await configureActiveAccount(shouldSwitchAutomatically: true) else {
            // If no account can be set to active, go to the landing or carousel screen.
            let isCarouselEnabled: Bool = await services.configService.getFeatureFlag(
                .nativeCarouselFlow,
                isPreAuth: true
            )
            let introCarouselShown = await services.stateService.getIntroCarouselShown()
            let shouldShowCarousel = isCarouselEnabled && !introCarouselShown && !isInAppExtension
            return shouldShowCarousel ? .introCarousel : .landing
        }

        // If there's existing accounts, mark the carousel as shown.
        await setCarouselShownIfEnabled()

        // Check for a `logout` timeout action.
        let userId = activeAccount.profile.userId
        if await (try? services.authRepository.sessionTimeoutAction(userId: userId)) == .logout,
           await (try? services.vaultTimeoutService.sessionTimeoutValue(userId: userId)) != .never {
            return await handleAndRoute(.didTimeout(userId: activeAccount.profile.userId))
        }

        // Setup the unlock route for the active account.
        let event = AuthEvent.accountBecameActive(
            activeAccount,
            animated: false,
            attemptAutomaticBiometricUnlock: true,
            didSwitchAccountAutomatically: false
        )

        // Redirect the vault unlock screen if needed.
        return await handleAndRoute(event)
    }

    /// Handles the `.didTimeout`route and redirects the user to the correct screen based on active account state.
    ///
    ///   - Returns: A redirect to either `.didTimeout()`, `.landing`, or `prepareAndRedirect(.vaultUnlock())`.
    ///
    func timeoutRedirect(userId: String) async -> Route {
        do {
            // Ensure the timeout interval isn't `.never` and that the user has a timeout action.
            let vaultTimeoutInterval = try await services.vaultTimeoutService.sessionTimeoutValue(userId: userId)
            guard vaultTimeoutInterval != .never,
                  let action = try? await services.authRepository.sessionTimeoutAction(userId: userId) else {
                // If we have timed out a user with `.never` as a timeout or no timeout action,
                // no redirect is needed.
                return .complete
            }

            // Check the timeout action for the user.
            switch action {
            case .lock:
                // If there is a timeout and the user has a lock vault action,
                //  return `.vaultUnlock`.
                await services.authRepository.lockVault(userId: userId)
                guard let activeAccount = try? await services.authRepository.getAccount() else {
                    return .landing
                }
                // Setup the check route for the active account.
                let event = AuthEvent.accountBecameActive(
                    activeAccount,
                    animated: false,
                    attemptAutomaticBiometricUnlock: true,
                    didSwitchAccountAutomatically: false
                )

                return await handleAndRoute(event)
            case .logout:
                // If there is a timeout and the user has a logout vault action,
                //  log out the user.
                try await services.authRepository.logout(userId: userId, userInitiated: false)

                let account = try await services.authRepository.getAccount()
                return .landingSoftLoggedOut(email: account.profile.email)
            }
        } catch {
            services.errorReporter.log(error: error)
            // Go to landing.
            return .landing
        }
    }

    /// Configures state and suggests a redirect for the switch accounts route.
    ///
    /// - Parameters:
    ///   - isAutomatic: Did the user trigger the account switch?
    ///   - userId: The user Id of the selected account.
    /// - Returns: A suggested route for the active account with state pre-configured.
    ///
    func switchAccountRedirect(isAutomatic: Bool, userId: String) async -> AuthRoute {
        if let account = try? await services.authRepository.getAccount(),
           userId == account.profile.userId {
            return await handleAndRoute(
                .accountBecameActive(
                    account,
                    animated: false,
                    attemptAutomaticBiometricUnlock: true,
                    didSwitchAccountAutomatically: false
                )
            )
        }
        do {
            let activeAccount = try await services.authRepository.setActiveAccount(userId: userId)
            // Setup the unlock route for the active account.
            let event = AuthEvent.accountBecameActive(
                activeAccount,
                animated: false,
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: isAutomatic
            )
            return await handleAndRoute(event)
        } catch {
            services.errorReporter.log(error: error)
            return .landing
        }
    }

    /// Configures state and suggests a redirect for the `.vaultUnlock` route.
    ///
    /// - Parameters:
    ///    - activeAccount: The active account.
    ///    - animated: If the suggested route can be animated, use this value.
    ///    - shouldAttemptAutomaticBiometricUnlock: If the route uses automatic bioemtrics unlock,
    ///      this value enables or disables the feature.
    ///    - shouldAttemptAccountSwitch: Should the application automatically switch accounts for the user?
    /// - Returns: A suggested route for the active account with state pre-configured.
    ///
    func vaultUnlockRedirect(
        _ activeAccount: Account,
        animated: Bool,
        attemptAutomaticBiometricUnlock: Bool,
        didSwitchAccountAutomatically: Bool
    ) async -> AuthRoute {
        let userId = activeAccount.profile.userId
        do {
            let isLocked = try? await services.authRepository.isLocked(userId: userId)
            let vaultTimeout = try? await services.vaultTimeoutService.sessionTimeoutValue(userId: userId)

            switch (vaultTimeout, isLocked) {
            case (.never, true):
                // If the user has enabled Never Lock, but the vault is locked,
                // unlock the vault and return `.complete`.
                try await services.authRepository.unlockVaultWithNeverlockKey()
                return .completeWithNeverUnlockKey
            case (_, false):
                return .complete
            default:
                guard try await services.stateService.isAuthenticated(userId: userId) else {
                    return .landingSoftLoggedOut(email: activeAccount.profile.email)
                }

                let hasMasterPassword = activeAccount.profile.userDecryptionOptions?.hasMasterPassword == true

                if !hasMasterPassword {
                    let biometricUnlockStatus = try await services.biometricsRepository.getBiometricUnlockStatus()
                    if case .available(_, true, false) = biometricUnlockStatus {
                        return .enterpriseSingleSignOn(email: activeAccount.profile.email)
                    }
                }
                return .vaultUnlock(
                    activeAccount,
                    animated: animated,
                    attemptAutomaticBiometricUnlock: attemptAutomaticBiometricUnlock,
                    didSwitchAccountAutomatically: didSwitchAccountAutomatically
                )
            }
        } catch {
            // In case of an error, go to `.vaultUnlock` for the active user.
            services.errorReporter.log(error: error)
            return .vaultUnlock(
                activeAccount,
                animated: animated,
                attemptAutomaticBiometricUnlock: attemptAutomaticBiometricUnlock,
                didSwitchAccountAutomatically: didSwitchAccountAutomatically
            )
        }
    }

    /// Sets the flag indicating that the carousel was shown (or in the case of existing accounts,
    /// that it doesn't need to be shown again). This should be called on app launch if there's
    /// existing account or once logging in or creating an account is successful.
    ///
    private func setCarouselShownIfEnabled() async {
        let isCarouselEnabled: Bool = await services.configService.getFeatureFlag(.nativeCarouselFlow, isPreAuth: true)
        let introCarouselShown = await services.stateService.getIntroCarouselShown()
        if isCarouselEnabled, !introCarouselShown {
            await services.stateService.setIntroCarouselShown(true)
        }
    }
}
