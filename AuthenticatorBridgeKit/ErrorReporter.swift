/// A protocol for a service that can report non-fatal errors for investigation.
///
public protocol ErrorReporter: AnyObject {
    // MARK: Properties

    /// Whether collecting non-fatal errors and crash reports is enabled.
    var isEnabled: Bool { get set }

    // MARK: Methods

    /// Logs an error to be reported.
    ///
    /// - Parameter error: The error to log.
    ///
    func log(error: Error)
}
