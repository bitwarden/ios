// MARK: - FlightRecorderLogsAction

/// Actions handled by the `FlightRecorderLogsProcessor`.
///
enum FlightRecorderLogsAction: Equatable {
    /// Delete the specific flight recorder log.
    case delete(FlightRecorderLogMetadata)

    /// Delete all flight recorder logs.
    case deleteAll

    /// Dismiss the sheet.
    case dismiss

    /// Share the specific flight recorder log.
    case share(FlightRecorderLogMetadata)

    /// Share all flight recorder logs.
    case shareAll

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
