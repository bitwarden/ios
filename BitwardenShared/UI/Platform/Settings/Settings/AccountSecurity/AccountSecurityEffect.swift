// MARK: - AccountSecurityEffect

/// Effects handled by the `AccountSecurityProcessor`.
///
enum AccountSecurityEffect: Equatable {
    /// The account fingerprint phrase button was tapped.
    case accountFingerprintPhrasePressed

    /// The view has appeared.
    case appeared

    /// The user tapped the dismiss button on the set up unlock action card.
    case dismissSetUpUnlockActionCard

    /// Any initial data for the view should be loaded.
    case loadData

    /// The user's vault should be locked.
    ///
    case lockVault

    /// Stream the state of the badges in the settings tab.
    case streamSettingsBadge

    /// Unlock with Biometrics was toggled.
    case toggleUnlockWithBiometrics(Bool)

    /// Unlock with pin code was toggled.
    case toggleUnlockWithPINCode(Bool)
}
