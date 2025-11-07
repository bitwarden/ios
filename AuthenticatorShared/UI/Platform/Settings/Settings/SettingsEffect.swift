import BitwardenKit

// MARK: - SettingsEffect

/// Effects that can be processed by an `SettingsProcessor`.
enum SettingsEffect: Equatable {
    /// An effect for the flight recorder feature.
    case flightRecorder(FlightRecorderSettingsSectionEffect)

    /// The view appeared so the initial data should be loaded.
    case loadData

    /// The session timeout value was changed.
    case sessionTimeoutValueChanged(SessionTimeoutValue)

    /// Stream the active flight recorder log.
    case streamFlightRecorderLog

    /// Unlock with Biometrics was toggled.
    case toggleUnlockWithBiometrics(Bool)
}
