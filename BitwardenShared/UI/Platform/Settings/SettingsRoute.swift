/// A route to a specific screen in the settings tab.
///
public enum SettingsRoute: Equatable, Hashable {
    /// A route to the account security screen.
    case accountSecurity

    /// A route to display the specified alert.
    ///
    /// - Parameter alert: The alert to display.
    ///
    case alert(_ alert: Alert)

    /// A route to the auto-fill screen.
    case autoFill

    /// A route to the delete account screen.
    case deleteAccount

    /// A route to either the login view or vault unlock view upon account deletion.
    ///
    /// - Parameter hasOtherAccounts: Whether the user has other accounts.
    ///
    case didDeleteAccount(otherAccounts: [Account]?)

    /// A route that dismisses the current view.
    case dismiss

    /// A route to the login screen after the vault has been locked.
    ///
    /// - Parameters:
    ///   - account: The user's account
    ///
    case lockVault(account: Account)

    /// A route to log the user out.
    case logout

    /// A route to the other view.
    case other

    /// A route to the settings screen.
    case settings
}
