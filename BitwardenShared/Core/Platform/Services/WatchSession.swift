import WatchConnectivity

// MARK: - WatchSession

/// A protocol abstracting instance-level usage of `WCSession` to enable testability.
///
protocol WatchSession: AnyObject { // sourcery: AutoMockable
    /// The current activation state of the session.
    var activationState: WCSessionActivationState { get }

    /// The delegate for the session.
    var delegate: (any WCSessionDelegate)? { get set }

    /// Whether an Apple Watch is paired with the iPhone.
    var isPaired: Bool { get }

    /// Whether the Watch app is installed on the paired watch.
    var isWatchAppInstalled: Bool { get }

    /// Activates the session.
    func activate()

    /// Sends new state information to the paired and active Apple Watch.
    ///
    /// - Parameter applicationContext: A dictionary of state information to send.
    ///
    func updateApplicationContext(_ applicationContext: [String: Any]) throws
}

// MARK: - WCSession + WatchSession

extension WCSession: WatchSession {}

// MARK: - WatchSessionFactory

/// A factory that provides access to `WatchSession` and its static-level support check.
///
protocol WatchSessionFactory { // sourcery: AutoMockable
    /// Whether the current device supports Watch sessions.
    func isSupported() -> Bool

    /// Returns the default watch session if the device supports it, otherwise `nil`.
    func makeSession() -> (any WatchSession)?
}

// MARK: - DefaultWatchSessionFactory

/// The default `WatchSessionFactory` for the production app.
///
struct DefaultWatchSessionFactory: WatchSessionFactory {
    func isSupported() -> Bool {
        WCSession.isSupported()
    }

    func makeSession() -> (any WatchSession)? {
        guard WCSession.isSupported() else { return nil }
        return WCSession.default
    }
}
