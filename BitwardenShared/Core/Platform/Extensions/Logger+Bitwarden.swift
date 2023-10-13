import OSLog

extension Logger {
    // MARK: Type Properties

    /// Logger instance for general application-level logs.
    static let application = Logger(subsystem: subsystem, category: "Application")

    // MARK: Private

    /// The Logger subsystem passed along with logs to the logging system to identify logs from this
    /// application.
    private static var subsystem = Bundle.main.bundleIdentifier!
}
