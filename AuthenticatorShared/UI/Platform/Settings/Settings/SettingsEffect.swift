// MARK: - SettingsEffect

/// Effects that can be processed by an `SettingsProcessor`.
enum SettingsEffect {
    /// The view appeared so the initial data should be loaded.
    case loadData

    /// Unlock with Biometrics was toggled.
    case toggleUnlockWithBiometrics(Bool)
}
