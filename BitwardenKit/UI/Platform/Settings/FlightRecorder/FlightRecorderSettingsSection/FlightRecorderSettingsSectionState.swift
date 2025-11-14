import BitwardenResources
import Foundation

// MARK: - FlightRecorderSettingsSectionState

/// The state for the Flight Recorder settings section component.
///
/// This is a reusable component that can be integrated into any processor that displays Flight
/// Recorder settings.
///
public struct FlightRecorderSettingsSectionState: Equatable {
    // MARK: Properties

    /// The Flight Recorder's active log metadata, if logging is enabled.
    public var activeLog: FlightRecorderData.LogMetadata?

    // MARK: Computed Properties

    /// The accessibility label for the Flight Recorder toggle.
    var flightRecorderToggleAccessibilityLabel: String {
        var accessibilityLabelComponents = [Localizations.flightRecorder]
        if let log = activeLog {
            // VoiceOver doesn't read the short date style correctly so use the medium style instead.
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium

            accessibilityLabelComponents.append(Localizations.loggingEndsOnDateAtTime(
                dateFormatter.string(from: log.endDate),
                log.formattedEndTime,
            ))
        }
        return accessibilityLabelComponents.joined(separator: ", ")
    }

    // MARK: Initialization

    /// Creates a new `FlightRecorderState`.
    ///
    /// - Parameter activeLog: The Flight Recorder's active log metadata, if logging is enabled.
    ///
    public init(activeLog: FlightRecorderData.LogMetadata? = nil) {
        self.activeLog = activeLog
    }
}
