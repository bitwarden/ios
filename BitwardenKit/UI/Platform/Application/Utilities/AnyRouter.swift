// MARK: - AnyRouter

/// A type erased wrapper for a router.
///
open class AnyRouter<Event, Route>: Router {
    // MARK: Properties

    /// A closure that wraps the `handleAndRoute()` method.
    private let doHandleAndRoute: (Event) async -> Route

    // MARK: Initialization

    /// Initializes an `AnyRouter`.
    ///
    /// - Parameter router: The router to wrap.
    ///
    public init<R: Router>(_ router: R) where R.Route == Route, R.Event == Event {
        doHandleAndRoute = { event in
            await router.handleAndRoute(event)
        }
    }

    // MARK: Router

    open func handleAndRoute(_ event: Event) async -> Route {
        await doHandleAndRoute(event)
    }
}

// MARK: - Router Extensions

public extension Router {
    /// Wraps this router in an instance of `AnyRouter`.
    ///
    /// - Returns: An `AnyRouter` instance wrapping this router.
    func asAnyRouter() -> AnyRouter<Event, Route> {
        AnyRouter(self)
    }
}
