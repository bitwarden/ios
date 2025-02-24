// MARK: - SettingsEffect

/// Effects that can be processed by an `SettingsProcessor`.
enum SettingsEffect: Equatable {
    /// The view appeared so the initial data should be loaded.
    case loadData

    /// The session timeout value was changed.
    case sessionTimeoutValueChanged(SessionTimeoutValue)

    /// Unlock with Biometrics was toggled.
    case toggleUnlockWithBiometrics(Bool)
}
