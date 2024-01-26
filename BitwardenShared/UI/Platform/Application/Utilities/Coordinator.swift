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

// swiftlint:disable weak_navigator

/// A protocol for an object that has a `Navigator`.
///
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
