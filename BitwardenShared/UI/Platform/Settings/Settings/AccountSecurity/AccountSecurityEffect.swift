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

    /// The user's vault was locked.
    ///
    /// - Parameter userInitiated: Did a user action trigger this lock event.
    ///
    case lockVault(userInitiated: Bool)

    /// Unlock with Biometrics was toggled.
    case toggleUnlockWithBiometrics(Bool)
}
