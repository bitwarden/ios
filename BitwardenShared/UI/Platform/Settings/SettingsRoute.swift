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

    /// A route to the appearance screen.
    case appearance

    /// A route to the app extension screen.
    case appExtension

    /// A route to the app extension setup sheet.
    case appExtensionSetup

    /// A route to the auto-fill screen.
    case autoFill

    /// A route to the delete account screen.
    case deleteAccount

    /// A route that dismisses the current view.
    case dismiss

    /// A route to the export vault view.
    case exportVault

    /// A route to view the folders in the vault.
    case folders

    /// A route to view a login request.
    ///
    /// - Parameter loginRequest: The login request to display.
    ///
    case loginRequest(_ loginRequest: LoginRequest)

    /// A route to the other view.
    case other

    /// A route to the password auto-fill screen.
    case passwordAutoFill

    /// A route to the pending login requests view.
    case pendingLoginRequests

    /// A route to view the select language view.
    ///
    /// - Parameter currentLanguage: The currently selected language option.
    ///
    case selectLanguage(currentLanguage: LanguageOption)

    /// A route to the settings screen.
    case settings

    /// A route to the vault settings view.
    case vault
}
