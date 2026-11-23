import BitwardenSdk

// MARK: - SavePasswordMatch

/// How a save-password request relates to the logins already in the vault.
///
public enum SavePasswordMatch: Equatable {
    /// A login with the same URI, username and password already exists, so nothing needs saving.
    case identical(CipherView)

    /// No existing login matches the request, so a new login should be added.
    case none

    /// Exactly one editable login has the same URI and username, so its password can be updated
    /// without asking the user.
    case singleUpdateCandidate(CipherView)

    /// The request matches editable logins that the user needs to choose between: either several
    /// logins have the same URI and username, or the request has no username.
    case updateCandidates([CipherView])
}
