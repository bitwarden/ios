// MARK: AuthAction

/// An action that may require routing to a new Auth screen.
///
public enum AuthAction: Equatable {
    /// When the app should lock an account.
    ///
    /// - Parameters:
    ///   - userId: The user Id of the selected account. Defaults to the active user id if nil.
    ///   - isManuallyLocking: Whether the user is manually locking the account.
    ///
    case lockVault(userId: String?, isManuallyLocking: Bool = false)

    /// When the app should logout an account vault.
    ///
    /// - Parameters:
    ///   - userId: The user Id of the selected account. Defaults to the active user id if nil.
    ///   - userInitiated: Did a user action trigger the logout.
    ///
    case logout(userId: String?, userInitiated: Bool)

    /// When the app requests an account switch.
    ///
    /// - Parameters:
    ///   - isAutomatic: Did the system trigger the account switch?
    ///   - userId: The user Id of the selected account.
    ///   - authCompletionRoute: An optional route that should be navigated to after switching
    ///     accounts and vault unlock
    ///
    case switchAccount(isAutomatic: Bool, userId: String, authCompletionRoute: AppRoute? = nil)
}
