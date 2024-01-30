import Foundation

// swiftlint:disable file_length

// MARK: - AuthEvent

public enum AuthEvent: Equatable {
    /// When the router should check the lock status of an account and propose a route.
    ///
    /// - Parameters:
    ///   - account: The account to unlock the vault for.
    ///   - animated: Whether to animate the transition to the view.
    ///   - attemptAutomaticBiometricUnlock: If `true` and biometric unlock is enabled/available,
    ///     the processor should attempt an automatic biometric unlock.
    ///   - didSwitchAccountAutomatically: A flag indicating if the active account was switched automatically.
    ///
    case accountBecameActive(
        Account,
        animated: Bool,
        attemptAutomaticBiometricUnlock: Bool,
        didSwitchAccountAutomatically: Bool
    )

    /// When the router should handle an AuthAction.
    ///
    case action(AuthAction)

    /// When the router should check the lock status of an account and propose a route.
    ///
    /// - Parameters:
    ///   - account: The account to unlock the vault for.
    ///   - animated: Whether to animate the transition to the view.
    ///   - attemptAutomaticBiometricUnlock: If `true` and biometric unlock is enabled/available,
    ///     the processor should attempt an automatic biometric unlock.
    ///   - didSwitchAccountAutomatically: A flag indicating if the active account was switched automatically.
    ///
    case didLockAccount(
        Account,
        animated: Bool,
        attemptAutomaticBiometricUnlock: Bool,
        didSwitchAccountAutomatically: Bool
    )

    /// When the user deletes an account.
    case didDeleteAccount

    /// When the user logs out from an account.
    ///
    /// - Parameters:
    ///   - userId: The userId of the account that was logged out.
    ///   - isUserInitiated: Did a user action trigger the account switch?
    ///
    case didLogout(userId: String, userInitiated: Bool)

    /// When the app starts
    case didStart

    /// When an account has timed out.
    case didTimeout(userId: String)
}

public enum AuthAction: Equatable {
    /// When the app should lock an account.
    ///
    /// - Parameter userId: The user Id of the account.
    ///
    case lockVault(userId: String?)

    /// When the app should logout an account vault.
    ///
    /// - Parameters:
    ///   - userId: The user Id of the selected account.
    ///   - userInitiated: Did a user action trigger the logout.
    ///     Defaults to the active user id if nil.
    ///
    case logout(userId: String?, userInitiated: Bool)

    /// When the app requests an account switch.
    ///
    /// - Parameters:
    ///   - isAutomatic: Did the system trigger the account switch?
    ///   - userId: The user Id of the selected account.
    ///
    case switchAccount(isAutomatic: Bool, userId: String)
}

// MARK: - AuthManager

final class AuthRouter: NSObject, Router {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasStateService
        & HasVaultTimeoutService

    /// The services used by this router.
    let services: Services

    // MARK: Initialization

    /// Creates a new `AuthRouter`.
    ///
    /// - Parameter services: The services used by this router.
    ///
    /// - Parameters:
    init(services: Services) {
        self.services = services
    }

    /// Prepare the coordinator asynchronously for a redirected `AuthRoute` based on current state
    ///
    /// - Parameter route: The proposed `AuthRoute`.
    /// - Returns: Either the supplied route or a new route if the coordinator state demands a different route.
    ///
    func handleAndRoute(_ event: AuthEvent) async -> AuthRoute {
        switch event {
        case let .accountBecameActive(
            activeAccount,
            animated,
            attemptAutomaticBiometricUnlock,
            didSwitchAccountAutomatically
        ):
            return await vaultUnlockRedirect(
                activeAccount,
                animated: animated,
                attemptAutomaticBiometricUnlock: attemptAutomaticBiometricUnlock,
                didSwitchAccountAutomatically: didSwitchAccountAutomatically
            )
        case let .action(authAction):
            return await handleAuthAction(authAction)
        case .didDeleteAccount:
            return await deleteAccountRedirect()
        case let .didLockAccount(
            account,
            animated,
            attemptAutomaticBiometricUnlock,
            didSwitchAccountAutomatically
        ):
            guard let active = try? await services.authRepository.getAccount() else {
                return .landing
            }
            guard active.profile.userId == account.profile.userId else {
                return await vaultUnlockRedirect(
                    active,
                    animated: animated,
                    attemptAutomaticBiometricUnlock: attemptAutomaticBiometricUnlock,
                    didSwitchAccountAutomatically: didSwitchAccountAutomatically
                )
            }
            return .vaultUnlock(
                account,
                animated: animated,
                attemptAutomaticBiometricUnlock: attemptAutomaticBiometricUnlock,
                didSwitchAccountAutomatically: didSwitchAccountAutomatically
            )
        case let .didLogout(userId, userInitiated):
            return await didLogoutRedirect(
                userId: userId,
                userInitiated: userInitiated
            )
        case .didStart:
            // Go to the initial auth route redirect.
            return await preparedStartRoute()
        case let .didTimeout(userId):
            return await timeoutRedirect(userId: userId)
        }
    }

    // MARK: - Private

    private func handleAuthAction(_ action: AuthAction) async -> AuthRoute {
        switch action {
        case let .lockVault(userId):
            return await lockVaultRedirect(userId: userId)
        case let .logout(userId, userInitiated):
            return await logoutRedirect(userId: userId, userInitiated: userInitiated)
        case let .switchAccount(isAutomatic, userId):
            return await switchAccountRedirect(
                isAutomatic: isAutomatic,
                userId: userId
            )
        }
    }
}

// MARK: Redirects

private extension AuthRouter {
    /// Configures the app with an active account.
    ///
    /// - Parameter shouldSwitchAutomatically: Should the app switch to the next available account
    ///     if there is no active account?
    /// - Returns: The account model currently set as active.
    ///
    private func configureActiveAccount(shouldSwitchAutomatically: Bool) async throws -> Account {
        if let active = try? await services.stateService.getActiveAccount() {
            return active
        }
        guard shouldSwitchAutomatically,
              let alternate = try await services.stateService.getAccounts().first else {
            throw StateServiceError.noActiveAccount
        }
        return try await services.authRepository.setActiveAccount(userId: alternate.profile.userId)
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

    /// Handles the `.logout()`action and redirects the user to the correct screen.
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
            try await services.authRepository.logout(userId: accountToLogOut.profile.userId)
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
    private func preparedStartRoute() async -> AuthRoute {
        guard let activeAccount = try? await configureActiveAccount(shouldSwitchAutomatically: true) else {
            // If no account can be set to active, go to the landing screen.
            return .landing
        }
        // Check for the `onAppRestart` timeout condition.
        let vaultTimeout = try? await services.vaultTimeoutService
            .sessionTimeoutValue(userId: activeAccount.profile.userId)
        if vaultTimeout == .onAppRestart {
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
                  let action = try? await services.stateService.getTimeoutAction(userId: userId) else {
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
                guard let activeAccount = try? await services.stateService.getActiveAccount(),
                      activeAccount.profile.userId == userId else {
                    return .complete
                }
                // Setup the unlock route for the active account.
                let event = AuthEvent.accountBecameActive(
                    activeAccount,
                    animated: false,
                    attemptAutomaticBiometricUnlock: true,
                    didSwitchAccountAutomatically: false
                )
                // Redirect the vault unlock
                return await handleAndRoute(event)
            case .logout:
                // If there is a timeout and the user has a logout vault action,
                //  log out the user.
                try await services.authRepository.logout(userId: userId)

                // Go to landing.
                return .landing
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
    ///   - isUserInitiated: Did the user trigger the account switch?
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
    ///     - activeAccount: The active account.
    ///     - animated: If the suggested route can be animated, use this value.
    ///     - shouldAttemptAutomaticBiometricUnlock: If the route uses automatic bioemtrics unlock,
    ///         this value enables or disables the feature.
    ///     - shouldAttemptAccountSwitch: Should the application automatically switch accounts for the user?
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
            // Check for Never Lock.
            let isLocked = try? await services.authRepository.isLocked(userId: userId)
            let vaultTimeout = try? await services.vaultTimeoutService.sessionTimeoutValue(userId: userId)

            switch (vaultTimeout, isLocked) {
            case (.never, true):
                // If the user has enabled Never Lock, but the vault is locked,
                //  unlock the vault and return `.complete`.
                try await services.authRepository.unlockVaultWithNeverlockKey()
                return .complete
            case (_, false):
                // If the  vault is unlocked, return `.complete`.
                return .complete
            default:
                // Otherwise, return `.vaultUnlock`.
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
}

/// A protocol for an object that configures state for a given event and outputs a redirected route.
@MainActor
public protocol Router<Event, Route>: AnyObject {
    associatedtype Event
    associatedtype Route

    /// Prepare the coordinator for a given route and redirect if needed.
    ///
    /// - Parameter route: The route for which the coordinator should prepare itself.
    /// - Returns: A redirected route for which the Coordinator is prepared.
    ///
    func handleAndRoute(_ event: Event) async -> Route
}

// MARK: - AnyRouter

/// A type erased wrapper for a router.
///
open class AnyRouter<Event, Route>: Router {
    // MARK: Properties

    /// A closure that wraps the `handleAndRoute()` method.
    private let doHandleAndRoute: (Event) async -> Route

    // MARK: Initialization

    /// Initializes an `AnyRouter`.
    ///
    /// - Parameter router: The router to wrap.
    ///
    public init<R: Router>(_ router: R) where R.Route == Route, R.Event == Event {
        doHandleAndRoute = { event in
            await router.handleAndRoute(event)
        }
    }

    // MARK: Router

    open func handleAndRoute(_ event: Event) async -> Route {
        await doHandleAndRoute(event)
    }
}

// MARK: - Router Extensions

public extension Router {
    /// Wraps this router in an instance of `AnyRouter`.
    ///
    /// - Returns: An `AnyRouter` instance wrapping this router.
    func asAnyRouter() -> AnyRouter<Event, Route> {
        AnyRouter(self)
    }
}
