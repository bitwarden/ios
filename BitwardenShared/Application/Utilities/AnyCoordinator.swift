// MARK: - AnyCoordinator

/// A type erased wrapper for a coordinator.
///
open class AnyCoordinator<Route>: Coordinator {
    // MARK: Properties

    /// A closure that wraps the `navigate(to:)` method.
    private let doNavigate: (Route, AnyObject?) -> Void

    /// A closure that wraps the `start()` method.
    private let doStart: () -> Void

    // MARK: Initialization

    /// Initializes an `AnyCoordinator`.
    ///
    /// - Parameter coordinator: The coordinator to wrap.
    ///
    public init<C: Coordinator>(_ coordinator: C) where C.Route == Route {
        doNavigate = { route, context in
            coordinator.navigate(to: route, context: context)
        }
        doStart = { coordinator.start() }
    }

    // MARK: Coordinator

    open func navigate(to route: Route, context: AnyObject?) {
        doNavigate(route, context)
    }

    open func start() {
        doStart()
    }
}

// MARK: - Coordinator Extensions

public extension Coordinator {
    /// Wraps this coordinator in an instance of `AnyCoordinator`.
    ///
    /// - Returns: An `AnyCoordinator` instance wrapping this coordinator.
    func asAnyCoordinator() -> AnyCoordinator<Route> {
        AnyCoordinator(self)
    }
}
