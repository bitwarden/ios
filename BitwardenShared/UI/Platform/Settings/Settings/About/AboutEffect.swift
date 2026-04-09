import BitwardenKit

// MARK: - AboutEffect

/// Effects that can be processed by the `AboutProcessor`.
///
enum AboutEffect: Equatable {
    /// Copy the version information to the pasteboard.
    case copyVersionInfo

    /// An effect for the Flight Recorder feature.
    case flightRecorder(FlightRecorderSettingsSectionEffect)

    /// Stream the active flight recorder log.
    case streamFlightRecorderLog
}
