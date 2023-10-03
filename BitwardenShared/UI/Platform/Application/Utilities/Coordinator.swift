/// A protocol for an object that performs navigation via routes.
@MainActor
public protocol Coordinator<Route>: AnyObject {
    associatedtype Route

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

    /// Shows the loading overlay view.
    ///
    /// - Parameter state: The state for configuring the loading overlay.
    ///
    func showLoadingOverlay(_ state: LoadingOverlayState)

    /// Starts the coordinator, displaying its content.
    ///
    func start()
}

public extension Coordinator {
    /// Navigate to the screen associated with the given `Route` without context.
    ///
    /// - Parameters:
    ///     - route: The specific `Route` to navigate to.
    ///
    func navigate(to route: Route) {
        navigate(to: route, context: nil)
    }
}
