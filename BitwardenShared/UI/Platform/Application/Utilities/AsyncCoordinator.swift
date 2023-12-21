// MARK: - AsyncCoordinator

/// A protocol extension of `Coordinator` that performs navigation via async routes.
///
@MainActor
public protocol AsyncCoordinator<Route, AsyncRoute>: Coordinator {
    associatedtype Route
    associatedtype AsyncRoute

    /// Hides the loading overlay view.
    ///
    func hideLoadingOverlay()

    /// Navigate to the screen associated with the given `Route` with the given context.
    ///
    /// - Parameters:
    ///     - route: The specific `Route` to navigate to.
    ///     - context: An object representing the context where the navigation occurred.
    ///
    func navigate(to route: Route, context: AnyObject?)

    /// Shows the provided alert on the `stackNavigator`.
    ///
    /// - Parameter alert: The alert to show.
    ///
    func showAlert(_ alert: Alert)

    /// Shows the loading overlay view.
    ///
    /// - Parameter state: The state for configuring the loading overlay.
    ///
    func showLoadingOverlay(_ state: LoadingOverlayState)

    /// Starts the coordinator, displaying its content.
    ///
    func start()

    /// Navigate to the screen associated with the given `AsyncRoute` when the route may be async.
    ///
    /// - Parameters:
    ///     - route:  Navigate to this `AsyncRoute` with delay.
    ///     - context: An object representing the context where the navigation occurred.
    ///
    func waitAndNavigate(to route: AsyncRoute, context: AnyObject?) async
}

// MARK: - Extensions

public extension AsyncCoordinator {
    /// Navigate to the screen associated with the given `AsyncRoute` without context.
    ///
    /// - Parameters:
    ///     - route: The specific `AsyncRoute` to navigate to.
    ///
    func waitAndNavigate(to route: AsyncRoute) async {
        await waitAndNavigate(to: route, context: nil)
    }
}
