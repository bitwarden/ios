import BitwardenSdk

// MARK: - SavePasswordMatch

/// How a save-password request relates to the logins already in the vault.
///
public enum SavePasswordMatch: Equatable {
    /// A login with the same URI, username and password already exists, so nothing needs saving.
    case identical(CipherView)

    /// No existing login matches the request, so a new login should be added.
    case none

    /// Exactly one login that the user can edit and see the password of matches the URI and username
    /// and is saved for the same host, so its password can be updated.
    case singleUpdateCandidate(CipherView)
}
