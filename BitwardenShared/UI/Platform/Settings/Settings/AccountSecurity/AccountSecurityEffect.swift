// MARK: - AccountSecurityEffect

/// Effects handled by the `AccountSecurityProcessor`.
///
enum AccountSecurityEffect: Equatable {
    /// The account fingerprint phrase button was tapped.
    case accountFingerprintPhrasePressed

    /// The view appeared so the initial data should be loaded.
    case loadData

    /// The user's vault was locked.
    case lockVault

    /// Unlock with Biometrics was toggled.
    case toggleUnlockWithBiometrics(Bool)
}
