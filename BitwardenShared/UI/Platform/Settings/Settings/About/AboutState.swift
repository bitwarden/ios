import Foundation

// MARK: - AboutState

/// An object that defines the current state of the `AboutView`.
///
struct AboutState {
    /// The copyright text.
    var copyrightText = "© Bitwarden Inc. 2015-\(Calendar.current.component(.year, from: Date.now))"

    /// Whether the submit crash logs toggle is on.
    var isSubmitCrashLogsToggleOn: Bool = false

    /// The version of the app.
    var version: String = "\(Localizations.version): \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))"
}
