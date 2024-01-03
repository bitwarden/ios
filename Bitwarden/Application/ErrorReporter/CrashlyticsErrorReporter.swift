import BitwardenShared
import FirebaseCore
import FirebaseCrashlytics

/// An `ErrorReporter` that logs non-fatal errors to Crashlytics for investigation.
///
final class CrashlyticsErrorReporter: ErrorReporter {
    // MARK: ErrorReporter Properties

    var isEnabled: Bool {
        get { Crashlytics.crashlytics().isCrashlyticsCollectionEnabled() }
        set {
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(newValue)
        }
    }

    // MARK: Initialization

    /// Initialize the `CrashlyticsErrorReporter`.
    ///
    init() {
        FirebaseApp.configure()
    }

    // MARK: ErrorReporter

    func log(error: Error) {
        // Don't log networking related errors to Crashlytics.
        guard !error.isNetworkingError else { return }

        Crashlytics.crashlytics().record(error: error)
    }
}
