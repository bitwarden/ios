import BitwardenKit
import BitwardenShared
import FirebaseCore
import FirebaseCrashlytics

/// An `ErrorReporter` that logs non-fatal errors to Crashlytics for investigation.
///
final class CrashlyticsErrorReporter: ErrorReporter {
    // MARK: Static Properties

    /// Shared singleton error reporter to make sure we don't configure Firebase twice, which throws an error.
    static let shared = CrashlyticsErrorReporter()

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
    private init() {
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
        guard isEnabled else {
            return
        }
        Crashlytics.crashlytics().setCustomValue(appContext, forKey: "AppContext")
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
