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

    /// Shows the alert.
    ///
    /// - Parameters:
    ///   - alert: The alert to show.
    ///   - onDismissed: An optional closure that is called when the alert is dismissed.
    ///
    func showAlert(_ alert: Alert, onDismissed: (() -> Void)?)

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

    /// Shows the provided alert on the `stackNavigator`.
    ///
    /// - Parameter alert: The alert to show.
    ///
    func showAlert(_ alert: Alert) {
        showAlert(alert, onDismissed: nil)
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
        navigator?.hideLoadingOverlay()
    }

    /// Shows the provided alert on the `stackNavigator`.
    ///
    /// - Parameters:
    ///   - alert: The alert to show.
    ///   - onDismissed: An optional closure that is called when the alert is dismissed.
    ///
    func showAlert(_ alert: Alert, onDismissed: (() -> Void)? = nil) {
        navigator?.present(alert, onDismissed: onDismissed)
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
