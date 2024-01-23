import OSLog

extension Logger {
    // MARK: Type Properties

    /// Logger instance for the app's action extension.
    static let appExtension = Logger(subsystem: subsystem, category: "AppExtension")

    /// Logger instance for general application-level logs.
    static let application = Logger(subsystem: subsystem, category: "Application")

    /// Logger instance for use by processors in the application.
    static let processor = Logger(subsystem: subsystem, category: "Processor")

    // MARK: Private

    /// The Logger subsystem passed along with logs to the logging system to identify logs from this
    /// application.
    private static var subsystem = Bundle.main.bundleIdentifier!
}
