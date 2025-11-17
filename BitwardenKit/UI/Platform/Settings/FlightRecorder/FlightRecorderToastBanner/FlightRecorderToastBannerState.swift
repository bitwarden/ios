// MARK: - FlightRecorderToastBannerState

/// The state for the flight recorder toast banner that displays when a flight recorder log is active.
///
public struct FlightRecorderToastBannerState: Equatable {
    // MARK: Properties

    /// The active flight recorder log metadata, or `nil` if the flight recorder isn't active.
    public var activeLog: FlightRecorderData.LogMetadata?

    // MARK: Computed Properties

    /// Whether the flight recorder toast banner is visible.
    public var isToastBannerVisible: Bool {
        !(activeLog?.isBannerDismissed ?? true)
    }

    // MARK: Initialization

    /// Initialize a `FlightRecorderToastBannerState`.
    ///
    /// - Parameter activeLog: The active flight recorder log metadata, or `nil` if the flight recorder
    ///     isn't active.
    ///
    public init(activeLog: FlightRecorderData.LogMetadata? = nil) {
        self.activeLog = activeLog
    }
}
