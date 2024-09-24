import OSLog

public extension Logger {
    // MARK: Type Properties

    /// Logger instance for the app's action extension.
    static let bridgeKit = Logger(subsystem: subsystem, category: "AuthenticatorBridgeKit")

    // MARK: Private

    /// The Logger subsystem passed along with logs to the logging system to identify logs from this
    /// application.
    private static let subsystem = Bundle.main.bundleIdentifier!
}
