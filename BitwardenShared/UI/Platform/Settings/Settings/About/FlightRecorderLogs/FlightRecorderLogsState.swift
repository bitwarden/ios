// MARK: - FlightRecorderLogsState

/// An object that defines the current state of the `FlightRecorderLogsView`.
///
struct FlightRecorderLogsState: Equatable {
    // MARK: Properties

    /// The list of flight recorder logs on the device.
    var logs = [FlightRecorderLogMetadata]()

    // MARK: Computed Properties

    /// Whether the delete all option is enabled.
    var isDeleteAllEnabled: Bool {
        logs.contains { !$0.isActiveLog }
    }

    /// Whether the share all option is enabled.
    var isShareAllEnabled: Bool {
        !logs.isEmpty
    }
}
