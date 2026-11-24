import BitwardenSdk

// MARK: - SavePasswordResolution

/// The outcome of resolving a save-password request against the logins already in the vault.
///
public enum SavePasswordResolution: Equatable {
    /// No existing login matches, so the user should be shown the screen to add a new login.
    case addNew

    /// The user needs to choose which existing login to update, for example because several logins
    /// match, the request has no username, or the login requires master password reprompt.
    case chooseLogin([CipherView])

    /// The request was handled without further input: an identical login already exists or a
    /// single matching login was updated.
    case completed
}
