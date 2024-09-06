import Foundation

// MARK: - AuthManager

final class AuthRouter: NSObject, Router {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasBiometricsRepository
        & HasClientService
        & HasConfigService
        & HasErrorReporter
        & HasStateService
        & HasVaultTimeoutService

    /// Whether the app is running as an extension.
    let isInAppExtension: Bool

    /// The services used by this router.
    let services: Services

    // MARK: Initialization

    /// Creates a new `AuthRouter`.
    ///
    /// - Parameters:
    ///   - isInAppExtension: Whether the app is running as an extension.
    ///   - services: The services used by this router.
    ///
    init(
        isInAppExtension: Bool,
        services: Services
    ) {
        self.isInAppExtension = isInAppExtension
        self.services = services
    }

    /// Prepare the coordinator asynchronously for a redirected `AuthRoute` based on current state.
    ///
    /// - Parameter route: The proposed `AuthRoute`.
    /// - Returns: Either the supplied route or a new route if the coordinator state demands a different route.
    ///
    func handleAndRoute(_ event: AuthEvent) async -> AuthRoute { // swiftlint:disable:this function_body_length
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
        case .didCompleteAuth:
            return await completeAuthRedirect()
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

    /// Converts an `AuthAction` into an `AuthRoute`
    ///
    /// - Parameter action: The supplied AuthAction.
    /// - Returns: The correct `AuthRoute` for the action.
    ///
    private func handleAuthAction(_ action: AuthAction) async -> AuthRoute {
        switch action {
        case let .lockVault(userId):
            return await lockVaultRedirect(userId: userId)
        case let .logout(userId, userInitiated):
            return await logoutRedirect(userId: userId, userInitiated: userInitiated)
        case let .switchAccount(isAutomatic, userId, _):
            return await switchAccountRedirect(
                isAutomatic: isAutomatic,
                userId: userId
            )
        }
    }
}
