// MARK: - AccountSecurityEffect

/// Effects handled by the `AccountSecurityProcessor`.
///
enum AccountSecurityEffect {
    /// The account fingerprint phrase button was tapped.
    case accountFingerprintPhrasePressed

    /// The user's vault was locked.
    case lockVault
}
