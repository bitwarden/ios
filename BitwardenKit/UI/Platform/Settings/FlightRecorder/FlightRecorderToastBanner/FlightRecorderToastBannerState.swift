// MARK: - FlightRecorderToastBannerState

/// The state for the flight recorder toast banner that displays when a flight recorder log is active.
///
public struct FlightRecorderToastBannerState: Equatable {
    // MARK: Properties

    /// The active flight recorder log metadata, or `nil` if the flight recorder isn't active.
    public var activeLog: FlightRecorderData.LogMetadata? {
        didSet {
            isToastBannerVisible = !(activeLog?.isBannerDismissed ?? true)
        }
    }

    /// Whether the flight recorder toast banner is visible.
    public var isToastBannerVisible = false

    // MARK: Initialization

    /// Initialize a `FlightRecorderToastBannerState`.
    ///
    /// - Parameters:
    ///   - activeLog: The active flight recorder log metadata, or `nil` if the flight recorder
    ///     isn't active.
    ///   - isToastBannerVisible: Whether the flight recorder toast banner is visible.
    ///
    public init(
        activeLog: FlightRecorderData.LogMetadata? = nil,
        isToastBannerVisible: Bool = false,
    ) {
        self.activeLog = activeLog
        self.isToastBannerVisible = isToastBannerVisible
    }
}
