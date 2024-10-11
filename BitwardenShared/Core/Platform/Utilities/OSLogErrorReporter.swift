import OSLog

/// An `ErrorReporter` that logs non-fatal errors to the console via OSLog.
///
public final class OSLogErrorReporter: ErrorReporter {
    // MARK: Properties

    /// The logger instance to log local messages.
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ErrorReporter")

    // MARK: ErrorReporter Properties

    /// This exists here satisfy the `ErrorReporter` protocol, but doesn't do anything since we
    /// don't report these errors to an external service.
    public var isEnabled = true

    // MARK: Initialization

    public init() {}

    // MARK: ErrorReporter

    public func log(error: Error) {
        logger.error("Error: \(error)")

        // Don't crash for networking related errors.
        guard !error.isNetworkingError else { return }

        // Crash in debug builds to make the error more visible during development.
        assertionFailure("Unexpected error: \(error)")
    }

    public func setRegion(_ region: String, isPreAuth: Bool) {
        // No-op
    }

    public func setUserId(_ userId: String?) {
        // No-op
    }
}
