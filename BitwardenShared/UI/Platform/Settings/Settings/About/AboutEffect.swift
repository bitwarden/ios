import BitwardenKit

// MARK: - AboutEffect

/// Effects that can be processed by the `AboutProcessor`.
///
enum AboutEffect: Equatable {
    /// An effect for the Flight Recorder feature.
    case flightRecorder(FlightRecorderSettingsSectionEffect)

    /// Stream the active flight recorder log.
    case streamFlightRecorderLog
}
