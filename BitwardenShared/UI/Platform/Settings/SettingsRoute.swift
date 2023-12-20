import BitwardenSdk

/// A route to a specific screen in the settings tab.
///
public enum SettingsRoute: Equatable, Hashable {
    /// A route to the about view.
    case about

    /// A route to the account security screen.
    case accountSecurity

    /// A route to add a new folder or edit an existing one.
    ///
    /// - Parameter folder: The existing folder to edit, if applicable.
    ///
    case addEditFolder(folder: FolderView?)

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
    /// - Parameter otherAccounts: An optional array of the user's other accounts.
    ///
    case didDeleteAccount(otherAccounts: [Account]?)

    /// A route that dismisses the current view.
    case dismiss

    /// A route to view the folders in the vault.
    case folders

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

    /// A route to the vault settings view.
    case vault
}
