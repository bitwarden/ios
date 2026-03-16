import AuthenticatorShared
import BitwardenKit
import FirebaseCore
import FirebaseCrashlytics

/// An `ErrorReporter` that logs non-fatal errors to Crashlytics for investigation.
///
final class CrashlyticsErrorReporter: ErrorReporter {
    // MARK: Properties

    /// A list of additional loggers that errors will be logged to.
    private var additionalLoggers: [any BitwardenLogger] = []

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

    func add(logger: any BitwardenLogger) {
        additionalLoggers.append(logger)
    }

    func log(error: Error) {
        let callStack = Thread.callStackSymbols.joined(separator: "\n")
        for logger in additionalLoggers {
            logger.log("Error: \(error)\n\(callStack)")
        }

        guard !error.isNonLoggableError else { return }

        Crashlytics.crashlytics().record(error: error)
    }

    func setAppContext(_ appContext: String) {
        // No-op
    }

    func setRegion(_ region: String, isPreAuth: Bool) {
        guard isEnabled else {
            return
        }
        Crashlytics.crashlytics().setCustomValue(region, forKey: isPreAuth ? "PreAuthRegion" : "Region")
    }

    func setUserId(_ userId: String?) {
        guard isEnabled else {
            return
        }
        Crashlytics.crashlytics().setUserID(userId)
    }
}
