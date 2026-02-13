/// A protocol for a service that can report non-fatal errors for investigation.
///
public protocol ErrorReporter: AnyObject {
    // MARK: Properties

    /// Whether collecting non-fatal errors and crash reports is enabled.
    var isEnabled: Bool { get set }

    // MARK: Methods

    /// Add an additional logger that will any errors will be logged to.
    ///
    /// - Parameter logger: The additional logger that any errors will be logged to.
    ///
    func add(logger: BitwardenLogger)

    /// Logs an error to be reported.
    ///
    /// - Parameter error: The error to log.
    ///
    func log(error: Error)

    /// Sets the current app context
    /// - Parameters:
    ///   - appContext: The context in which the app is running (either app or extension).
    func setAppContext(_ appContext: String)

    /// Sets the current region the user is on.
    /// - Parameters:
    ///   - region: Region the user is on (US, EU, SelfHosted).
    ///   - isPreAuth: Whether this region is being used pre authentication or when already authenticated.
    func setRegion(_ region: String, isPreAuth: Bool)

    /// Sets the current user iD to attach to errors.
    /// - Parameter userId: User ID to attach.
    func setUserId(_ userId: String?)
}
