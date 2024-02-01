// MARK: - AccountSecurityEffect

/// Effects handled by the `AccountSecurityProcessor`.
///
enum AccountSecurityEffect: Equatable {
    /// The account fingerprint phrase button was tapped.
    case accountFingerprintPhrasePressed

    /// The view has appeared.
    case appeared

    /// Any initial data for the view should be loaded.
    case loadData

    /// The user's vault should be locked.
    ///
    case lockVault

    /// Unlock with Biometrics was toggled.
    case toggleUnlockWithBiometrics(Bool)
}
