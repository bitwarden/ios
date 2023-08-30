/// A protocol for an object that performs navigation via routes.
@MainActor
public protocol Coordinator: AnyObject {
    associatedtype Route

    /// Navigate to the screen associated with the given `Route` with the given context.
    ///
    /// - Parameters:
    ///     - route: The specific `Route` to navigate to.
    ///     - context: An object representing the context where the navigation occurred.
    ///
    func navigate(to route: Route, context: AnyObject?)

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
