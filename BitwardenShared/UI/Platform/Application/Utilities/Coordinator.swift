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

    /// Navigate to the screen associated with the given `AsyncRoute` when the route may be async.
    ///
    /// - Parameters:
    ///     - route:  Navigate to this `Route` with delay.
    ///     - context: An object representing the context where the navigation occurred.
    ///
    func navigate(asyncTo route: Route, context: AnyObject?) async

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
}

/// A protocol for an object that has a `Navigator`.
///
protocol HasNavigator {
    var navigator: Navigator { get }
}

/// A protocol for an object that has a `StackNavigator`.
///
protocol HasStackNavigator: HasNavigator {
    var stackNavigator: StackNavigator { get }
}

/// A protocol for an object that has a `TabNavigator`.
///
protocol HasTabNavigator: HasNavigator {
    var tabNavigator: TabNavigator { get }
}

/// A protocol for an object that has a `RootNavigator`.
///
protocol HasRootNavigator: HasNavigator {
    var rootNavigator: RootNavigator { get }
}

// MARK: Extensions

public extension Coordinator {
    /// Navigate to the screen associated with the given `Route` without context.
    ///
    /// - Parameters:
    ///     - route: The specific `Route` to navigate to.
    ///
    func navigate(to route: Route) {
        navigate(to: route, context: nil)
    }

    /// Navigate to the screen associated with the given `Route` asynchronously without context.
    ///
    /// - Parameters:
    ///     - route: The specific `Route` to navigate to.
    ///
    func navigate(asyncTo route: Route) async {
        await navigate(asyncTo: route, context: nil)
    }

    /// Default to synchronous navigation
    ///
    func navigate(asyncTo route: Route, context: AnyObject?) async {
        navigate(to: route, context: context)
    }
}

extension Coordinator where Self: HasNavigator {
    /// Hides the loading overlay view.
    ///
    func hideLoadingOverlay() {
        navigator.hideLoadingOverlay()
    }

    /// Shows the provided alert on the `stackNavigator`.
    ///
    /// - Parameter alert: The alert to show.
    ///
    func showAlert(_ alert: Alert) {
        navigator.present(alert)
    }

    /// Shows the loading overlay view.
    ///
    /// - Parameter state: The state for configuring the loading overlay.
    ///
    func showLoadingOverlay(_ state: LoadingOverlayState) {
        navigator.showLoadingOverlay(state)
    }
}

extension HasStackNavigator {
    /// The stack navigator.
    var navigator: Navigator { stackNavigator }
}

extension HasTabNavigator {
    /// The tab navigator.
    var navigator: Navigator { tabNavigator }
}

extension HasRootNavigator {
    /// The root navigator.
    var navigator: Navigator { rootNavigator }
}
