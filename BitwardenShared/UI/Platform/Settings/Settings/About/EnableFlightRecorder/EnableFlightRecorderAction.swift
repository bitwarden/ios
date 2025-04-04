// MARK: - EnableFlightRecorderAction

/// Actions handled by the `EnableFlightRecorderProcessor`.
///
enum EnableFlightRecorderAction: Equatable {
    /// Dismiss the sheet.
    case dismiss

    /// The logging duration value has changed.
    case loggingDurationChanged(FlightRecorderLoggingDuration)
}
