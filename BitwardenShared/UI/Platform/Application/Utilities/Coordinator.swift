/// A protocol for an object that performs navigation via routes.
@MainActor
public protocol Coordinator<Route>: AnyObject {
    associatedtype Route

    // MARK: Methods

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
    ///     - withRedirect: Should the route be redirected if needed?
    ///     - context: An object representing the context where the navigation occurred.
    ///
    func navigate(asyncTo route: Route, withRedirect: Bool, context: AnyObject?) async

    /// Prepare the coordinator for a given route and redirect if needed.
    ///
    /// - Parameter route: The route for which the coordinator should prepare itself.
    /// - Returns: A redirected route for which the Coordinator is prepared.
    ///
    func prepareAndRedirect(_ route: Route) async -> Route

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

    /// Shows the toast.
    ///
    /// - Parameter text: The text of the toast to display.
    ///
    func showToast(_ text: String)

    /// Starts the coordinator, displaying its content.
    ///
    func start()
}

// swiftlint:disable weak_navigator

/// A protocol for an object that has a `Navigator`.
///
@MainActor
protocol HasNavigator {
    /// A weak reference to this item's `Navigator`. This value should be `weak`, otherwise a retain
    /// cycle might be introduced.
    var navigator: Navigator? { get }
}

/// A protocol for an object that has a `StackNavigator`.
///
@MainActor
protocol HasStackNavigator: HasNavigator {
    /// A weak reference to this item's `StackNavigator`. This value should be `weak`, otherwise a
    /// retain cycle might be introduced.
    var stackNavigator: StackNavigator? { get }
}

/// A protocol for an object that has a `TabNavigator`.
///
@MainActor
protocol HasTabNavigator: HasNavigator {
    /// A weak reference to this item's `TabNavigator`. This value should be `weak`, otherwise a
    /// retain cycle might be introduced.
    var tabNavigator: TabNavigator? { get }
}

/// A protocol for an object that has a `RootNavigator`.
///
@MainActor
protocol HasRootNavigator: HasNavigator {
    /// A weak reference to this item's `RootNavigator`. This value should be `weak`, otherwise a
    /// retain cycle might be introduced.
    var rootNavigator: RootNavigator? { get }
}

// MARK: Extensions

public extension Coordinator {
    /// Navigate to the screen associated with the given `Route` without context.
    ///
    /// - Parameters:
    ///     - route: The specific `Route` to navigate to.
    ///     - context: An object representing the context where the navigation occurred.
    ///
    func navigate(to route: Route) {
        navigate(to: route, context: nil)
    }

    /// Default to synchronous navigation
    ///
    /// - Parameters:
    ///     - route:  Navigate to this `Route` with delay.
    ///     - withRedirect: Should the route be redirected if needed?
    ///     - context: An object representing the context where the navigation occurred.
    ///
    func navigate(asyncTo route: Route, withRedirect: Bool, context: AnyObject?) async {
        navigate(to: route, context: context)
    }

    /// A helper for when not all parameters are needed.
    ///
    /// - Parameter route:  Navigate to this `Route` with delay.
    ///
    func navigate(asyncTo route: Route) async {
        await navigate(asyncTo: route, withRedirect: false, context: nil)
    }

    /// A helper for when not all parameters are needed.
    ///
    /// - Parameters:
    ///     - route:  Navigate to this `Route` with delay.
    ///     - withRedirect: Should the route be redirected if needed?
    ///
    func navigate(asyncTo route: Route, withRedirect: Bool) async {
        await navigate(asyncTo: route, withRedirect: withRedirect, context: nil)
    }

    /// A helper for when not all parameters are needed.
    ///
    /// - Parameters:
    ///     - route:  Navigate to this `Route` with delay.
    ///     - context: An object representing the context where the navigation occurred.
    ///
    func navigate(asyncTo route: Route, context: AnyObject?) async {
        await navigate(asyncTo: route, withRedirect: false, context: context)
    }

    /// Default to no preparation and no redirect for a route.
    ///
    func prepareAndRedirect(_ route: Route) async -> Route {
        route
    }
}

extension Coordinator where Self: HasNavigator {
    /// Hides the loading overlay view.
    ///
    func hideLoadingOverlay() {
        navigator?.hideLoadingOverlay()
    }

    /// Shows the provided alert on the `stackNavigator`.
    ///
    /// - Parameter alert: The alert to show.
    ///
    func showAlert(_ alert: Alert) {
        navigator?.present(alert)
    }

    /// Shows the loading overlay view.
    ///
    /// - Parameter state: The state for configuring the loading overlay.
    ///
    func showLoadingOverlay(_ state: LoadingOverlayState) {
        navigator?.showLoadingOverlay(state)
    }

    /// Shows the toast.
    ///
    /// - Parameter text: The text of the toast to display.
    ///
    func showToast(_ text: String) {
        navigator?.showToast(Toast(text: text))
    }
}

extension HasStackNavigator {
    /// The stack navigator.
    var navigator: Navigator? { stackNavigator }
}

extension HasTabNavigator {
    /// The tab navigator.
    var navigator: Navigator? { tabNavigator }
}

extension HasRootNavigator {
    /// The root navigator.
    var navigator: Navigator? { rootNavigator }
}

// swiftlint:enable weak_navigator
