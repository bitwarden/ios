// MARK: - VaultUnlockEffect

/// Asynchronous effects that can be handled by a `VaultUnlockProcessor`.
///
enum VaultUnlockEffect: Equatable {
    /// The unlock view appeared.
    case appeared

    /// The button to unlock with biometrics was pressed.
    case unlockWithBiometrics
}
