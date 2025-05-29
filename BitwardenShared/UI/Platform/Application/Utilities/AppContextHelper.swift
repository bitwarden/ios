/// Helper to know about the app context.
protocol AppContextHelper {
    /// The current app context.
    var appContext: AppContext { get }
}

/// Default implementation of `AppContextHelper`.
struct DefaultAppContextHelper: AppContextHelper {
    public private(set) var appContext: AppContext

    /// Initializes a `DefaultAppContextHelper`.
    /// - Parameter appcontext: The current `AppContext` mode.
    public init(appContext: AppContext) {
        self.appContext = appContext
    }
}
