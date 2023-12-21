// MARK: - AnyAsyncCoordinator

/// A type erased wrapper for a coordinator.
///
open class AnyAsyncCoordinator<Route, AsyncRoute>: AnyCoordinator<Route> {
    /// A closure that wraps the `navigate(to:)` method.
    private let doAsyncNavigate: (AsyncRoute, AnyObject?) async -> Void

    /// Initializes an `AnyCoordinator`.
    ///
    /// - Parameter coordinator: The coordinator to wrap.
    ///
    public init<C: AsyncCoordinator>(_ coordinator: C) where C.Route == Route, C.AsyncRoute == AsyncRoute {
        doAsyncNavigate = { route, context in
            await coordinator.waitAndNavigate(to: route, context: context)
        }
        super.init(coordinator)
    }

    open func waitAndNavigate(to route: AsyncRoute, context: AnyObject?) async {
        await doAsyncNavigate(route, context)
    }
}

// MARK: - Coordinator Extensions

public extension AsyncCoordinator {
    /// Wraps this coordinator in an instance of `AnyAsyncCoordinator`.
    ///
    /// - Returns: An `AnyCoordinator` instance wrapping this coordinator.
    func asAnyAsyncCoordinator() -> AnyAsyncCoordinator<Route, AsyncRoute> {
        AnyAsyncCoordinator(self)
    }
}
