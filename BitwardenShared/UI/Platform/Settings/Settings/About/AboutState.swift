import BitwardenResources
import Foundation

// MARK: - AboutState

/// An object that defines the current state of the `AboutView`.
///
struct AboutState {
    // MARK: Properties

    /// The URL for Bitwarden's app review page in the app store.
    var appReviewUrl: URL?

    /// The copyright text.
    var copyrightText = ""

    /// The flight recorder's active log metadata, if logging is enabled.
    var flightRecorderActiveLog: FlightRecorderData.LogMetadata?

    /// Whether the submit crash logs toggle is on.
    var isSubmitCrashLogsToggleOn: Bool = false

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The version of the app.
    var version = ""

    // MARK: Computed Properties

    /// The accessibility label for the flight recorder toggle.
    var flightRecorderToggleAccessibilityLabel: String {
        var accessibilityLabelComponents = [Localizations.flightRecorder]
        if let log = flightRecorderActiveLog {
            // VoiceOver doesn't read the short date style correctly so use the medium style instead.
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium

            accessibilityLabelComponents.append(Localizations.loggingEndsOnDateAtTime(
                dateFormatter.string(from: log.endDate),
                log.formattedEndTime
            ))
        }
        return accessibilityLabelComponents.joined(separator: ", ")
    }
}
