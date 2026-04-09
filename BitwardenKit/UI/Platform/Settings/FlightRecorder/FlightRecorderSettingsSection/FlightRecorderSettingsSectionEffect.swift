// MARK: - FlightRecorderSettingsSectionEffect

/// Effects handled by the Flight Recorder settings section component.
///
/// This is a reusable component that can be integrated into any processor that displays Flight
/// Recorder settings.
///
public enum FlightRecorderSettingsSectionEffect: Equatable {
    /// The Flight Recorder toggle value changed.
    case toggleFlightRecorder(Bool)
}
