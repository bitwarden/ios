import BitwardenShared
import FirebaseCore
import FirebaseCrashlytics
import OSLog

/// An `ErrorReporter` that logs non-fatal errors to Crashlytics for investigation.
///
final class CrashlyticsErrorReporter: ErrorReporter {
    // MARK: Properties

    /// The logger instance to log local messages.
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ErrorReporter")

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
        #if !DEBUG
        FirebaseApp.configure()
        #endif
    }

    // MARK: ErrorReporter

    func log(error: Error) {
        #if DEBUG
        logger.error("Error: \(error)")
        #else
        Crashlytics.crashlytics().record(error: error)
        #endif
    }
}
