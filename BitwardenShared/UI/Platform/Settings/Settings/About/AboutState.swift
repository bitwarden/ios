import BitwardenKit
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

    /// The state for the Flight Recorder feature.
    var flightRecorderState = FlightRecorderSettingsSectionState()

    /// Whether the submit crash logs toggle is on.
    var isSubmitCrashLogsToggleOn: Bool = false

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The version of the app.
    var version = ""
}
