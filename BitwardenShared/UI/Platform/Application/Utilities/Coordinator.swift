/// A protocol for an object that performs navigation via routes.
@MainActor
public protocol Coordinator<Route, Event>: AnyObject {
    // MARK: Types

    associatedtype Event
    associatedtype Route

    // MARK: Methods

    /// Handles events that may require asynchronous management.
    ///
    /// - Parameters:
    ///   - event: The event for which the coordinator handle.
    ///   - context: The context for the event.
    ///
    func handleEvent(_ event: Event, context: AnyObject?) async

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

    /// Shows the toast.
    ///
    /// - Parameter text: The text of the toast to display.
    ///
    func showToast(_ text: String)

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

/// A protocol for an object that has a `Router`.
///
protocol HasRouter<Event, Route> {
    associatedtype Event
    associatedtype Route

    var router: AnyRouter<Event, Route> { get }
}

// MARK: Extensions

public extension Coordinator {
    /// Handles events that may require asynchronous management.
    ///
    /// - Parameter event: The event for which the coordinator handle.
    ///
    func handleEvent(_ event: Event) async {
        await handleEvent(event, context: nil)
    }

    /// Navigate to the screen associated with the given `Route` without context.
    ///
    /// - Parameters:
    ///     - route: The specific `Route` to navigate to.
    ///     - context: An object representing the context where the navigation occurred.
    ///
    func navigate(to route: Route) {
        navigate(to: route, context: nil)
    }
}

extension Coordinator where Self.Event == Void {
    /// Provide a default No-Op when a coodrinator does not use events.
    ///
    func handleEvent(_ event: Void, context: AnyObject?) async {
        // No-Op
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

    /// Shows the toast.
    ///
    /// - Parameter text: The text of the toast to display.
    ///
    func showToast(_ text: String) {
        navigator.showToast(Toast(text: text))
    }
}

extension Coordinator where Self: HasRouter {
    /// Passes an `Event` to the router, which prepares a route
    ///  that the coordinator uses for navigation.
    ///
    /// - Parameter event: The event to pass to the router.
    ///
    func handleEvent(_ event: Event, context: AnyObject?) async {
        let route = await router.handleAndRoute(event)
        navigate(to: route, context: context)
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
