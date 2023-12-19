import Foundation

// MARK: - AboutState

/// An object that defines the current state of the `AboutView`.
///
struct AboutState {
    /// The current year.
    var currentYear: String = "\(Calendar.current.component(.year, from: Date.now))"

    /// Whether the submit crash logs toggle is on.
    var isSubmitCrashLogsToggleOn: Bool = false

    /// The version of the app.
    var version: String = ": \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))"
}
