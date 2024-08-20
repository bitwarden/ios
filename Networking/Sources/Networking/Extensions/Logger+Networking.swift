import OSLog

extension Logger {
    /// Logger instance for networking logs.
    static let networking = Logger(subsystem: subsystem, category: "Networking")

    /// The OSLog subsystem passed along with logs to the logging system to identify logs from this
    /// library.
    private static let subsystem = Bundle(for: HTTPService.self).bundleIdentifier!
}
