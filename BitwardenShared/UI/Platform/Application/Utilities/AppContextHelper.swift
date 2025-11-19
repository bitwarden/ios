/// Helper to know about the app context.
protocol AppContextHelper {
    /// The current app context.
    var appContext: AppContext { get }
}

/// Default implementation of `AppContextHelper`.
struct DefaultAppContextHelper: AppContextHelper {
    private(set) var appContext: AppContext
}
