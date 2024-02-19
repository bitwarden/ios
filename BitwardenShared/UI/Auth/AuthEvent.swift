// MARK: - AuthEvent

/// An event to be handled by a Router tasked with producing `AuthRoute`s.
///
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

    /// An action for when the router should check whether the account requires an updated password
    /// prior to completing auth and navigating to the vault.
    ///
    case didCompleteAuth

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
