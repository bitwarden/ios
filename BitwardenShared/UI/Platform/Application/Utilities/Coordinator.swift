import Foundation

/// A protocol for an object that performs navigation via routes.
@MainActor
protocol Coordinator<Route, Event>: AnyObject {
    // MARK: Types

    typealias ErrorAlertServices = HasConfigService & HasErrorReporter
    typealias ErrorAlertTryAgain = (() async -> Void)?

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

    /// Shows an alert for an error that occurred.
    ///
    /// - Parameters:
    ///   - error: The error that occurred, used to customize the details of the alert.
    ///   - services: A group of services used to gather additional information if the error details
    ///     are shared.
    ///   - tryAgain: An optional closure allowing the user to retry whatever triggered the error.
    ///
    func showErrorAlert(error: Error, services: ErrorAlertServices, tryAgain: (() async -> Void)?) async

    /// Shows the loading overlay view.
    ///
    /// - Parameter state: The state for configuring the loading overlay.
    ///
    func showLoadingOverlay(_ state: LoadingOverlayState)

    /// Shows the toast.
    ///
    /// - Parameters:
    ///   - title: The title text displayed in the toast.
    ///   - subtitle: The subtitle text displayed in the toast.
    ///   - additionalBottomPadding: Additional padding to apply to the bottom of the toast.
    ///
    func showToast(_ title: String, subtitle: String?, additionalBottomPadding: CGFloat)

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
@MainActor
protocol HasRouter<Event, Route> {
    associatedtype Event
    associatedtype Route

    var router: AnyRouter<Event, Route> { get }
}

// MARK: Extensions

extension Coordinator {
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

    /// Shows an alert for an error that occurred.
    ///
    /// - Parameters:
    ///   - error: The error that occurred, used to customize the details of the alert.
    ///   - services: A group of services used to gather additional information if the error details
    ///     are shared.
    ///
    func showErrorAlert(error: Error, services: ErrorAlertServices) async {
        await showErrorAlert(error: error, services: services, tryAgain: nil)
    }
}

extension Coordinator where Self.Event == Void {
    /// Provide a default No-Op when a coordinator does not use events.
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

    /// Shows an alert for an error that occurred.
    ///
    /// - Parameters:
    ///   - error: The error that occurred, used to customize the details of the alert.
    ///   - services: A group of services used to gather additional information if the error details
    ///     are shared.
    ///   - tryAgain: An optional closure allowing the user to retry whatever triggered the error.
    ///
    func showErrorAlert(error: Error, services: ErrorAlertServices, tryAgain: (() async -> Void)?) async {
        let alert = if await services.configService.getFeatureFlag(.mobileErrorReporting) {
            Alert.networkResponseError(error, shareErrorDetails: {
                // TODO: PM-18224 Show share sheet to export error details
            }, tryAgain: tryAgain)
        } else {
            Alert.networkResponseError(error, tryAgain: tryAgain)
        }
        showAlert(alert)
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
    /// - Parameters:
    ///   - title: The title text displayed in the toast.
    ///   - subtitle: The subtitle text displayed in the toast.
    ///   - additionalBottomPadding: Additional padding to apply to the bottom of the toast.
    ///
    func showToast(
        _ title: String,
        subtitle: String? = nil,
        additionalBottomPadding: CGFloat = 0
    ) {
        navigator?.showToast(
            Toast(title: title, subtitle: subtitle),
            additionalBottomPadding: additionalBottomPadding
        )
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
