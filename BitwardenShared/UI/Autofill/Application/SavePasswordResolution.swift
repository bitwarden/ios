import BitwardenSdk

// MARK: - SavePasswordResolution

/// The outcome of resolving a save-password request against the logins already in the vault.
///
public enum SavePasswordResolution: Equatable {
    /// No existing login matches, so the user should be shown the screen to add a new login.
    case addNew

    /// Several existing logins could be the one being updated, so the user needs to choose one.
    case chooseLogin([CipherView])

    /// The request was handled without further input: an identical login already exists or a
    /// single matching login was updated.
    case completed
}
