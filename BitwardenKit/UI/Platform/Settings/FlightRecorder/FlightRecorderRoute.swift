import Foundation

/// A route to a specific screen within the flight recorder flow.
///
public enum FlightRecorderRoute: Equatable, Hashable {
    /// A route that dismisses the current view.
    case dismiss

    /// A route to enable and configure flight recorder.
    case enableFlightRecorder

    /// A route to the flight recorder logs screen.
    case flightRecorderLogs

    /// A route to the share sheet to share a URL.
    case shareURL(URL)

    /// A route to the share sheet to share multiple URLs.
    case shareURLs([URL])
}
