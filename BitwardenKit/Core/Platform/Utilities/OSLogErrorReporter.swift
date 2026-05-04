import OSLog
import Security

/// An `ErrorReporter` that logs non-fatal errors to the console via OSLog.
///
public final class OSLogErrorReporter: ErrorReporter {
    // MARK: Properties

    /// A list of additional loggers that errors will be logged to.
    private var additionalLoggers: [any BitwardenLogger] = []

    /// The logger instance to log local messages.
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ErrorReporter")

    // MARK: ErrorReporter Properties

    /// This exists here satisfy the `ErrorReporter` protocol, but doesn't do anything since we
    /// don't report these errors to an external service.
    public var isEnabled = true

    // MARK: Initialization

    public init() {}

    // MARK: ErrorReporter

    public func add(logger: any BitwardenLogger) {
        additionalLoggers.append(logger)
    }

    public func log(error: Error) {
        logger.error("Error: \(error)")

        let callStack = Thread.callStackSymbols.joined(separator: "\n")
        for logger in additionalLoggers {
            logger.log("Error: \(error as NSError)\n\(callStack)")
        }

        let nsError = error as NSError
        if nsError.code == Int(errSecMissingEntitlement) {
            return
        }

        guard !error.isNonLoggableError else { return }

        if let keychainError = error as? KeychainServiceError,
           case let .osStatusError(status) = keychainError,
           status == errSecMissingEntitlement {
            return
        }

        #if !DISABLE_ASSERTION_FAILURE_ON_LOG_ERROR
        #if targetEnvironment(simulator)
        return
        #endif
        if Bundle.main.bundlePath.contains(".appex") {
            return
        }
        // Crash in debug builds to make the error more visible during development.
        assertionFailure("Unexpected error: \(error)")
        #endif
    }

    public func setAppContext(_ appContext: String) {
        // No-op
    }

    public func setRegion(_ region: String, isPreAuth: Bool) {
        // No-op
    }

    public func setUserId(_ userId: String?) {
        // No-op
    }
}
