// MARK: AuthAction

/// An action that may require routing to a new Auth screen.
///
public enum AuthAction: Equatable {
    /// When the app should lock an account.
    ///
    /// - Parameter userId: The user Id of the account.
    ///
    case lockVault(userId: String?)

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
    ///
    case switchAccount(isAutomatic: Bool, userId: String)
}
