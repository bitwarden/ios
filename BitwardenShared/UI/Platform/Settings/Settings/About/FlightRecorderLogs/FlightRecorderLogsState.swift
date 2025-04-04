// MARK: - FlightRecorderLogsState

/// An object that defines the current state of the `FlightRecorderLogsView`.
///
struct FlightRecorderLogsState: Equatable {
    // MARK: Properties

    /// The list of flight recorder logs on the device.
    var logs = [FlightRecorderLogMetadata]()
}
