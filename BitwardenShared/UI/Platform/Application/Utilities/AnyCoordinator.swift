// MARK: - AnyCoordinator

/// A type erased wrapper for a coordinator.
///
open class AnyCoordinator<Route>: Coordinator {
    // MARK: Properties

    /// A closure that wraps the `hideLoadingOverlay()` method.
    private let doHideLoadingOverlay: () -> Void

    /// A closure that wraps the `navigate(to:)` method.
    private let doNavigate: (Route, AnyObject?) -> Void

    /// A closure that wraps the `navigate(asyncTo:)` method.
    private let doAsyncNavigate: (Route, AnyObject?) async -> Void

    /// A closure that wraps the `showAlert(_:)` method.
    private let doShowAlert: (Alert) -> Void

    /// A closure that wraps the `showLoadingOverlay(_:)` method.
    private let doShowLoadingOverlay: (LoadingOverlayState) -> Void

    /// A closure that wraps the `start()` method.
    private let doStart: () -> Void

    // MARK: Initialization

    /// Initializes an `AnyCoordinator`.
    ///
    /// - Parameter coordinator: The coordinator to wrap.
    ///
    public init<C: Coordinator>(_ coordinator: C) where C.Route == Route {
        doHideLoadingOverlay = { coordinator.hideLoadingOverlay() }
        doAsyncNavigate = { route, context in
            await coordinator.navigate(asyncTo: route, context: context)
        }
        doNavigate = { route, context in
            coordinator.navigate(to: route, context: context)
        }
        doShowAlert = { coordinator.showAlert($0) }
        doShowLoadingOverlay = { coordinator.showLoadingOverlay($0) }
        doStart = { coordinator.start() }
    }

    // MARK: Coordinator

    open func navigate(to route: Route, context: AnyObject?) {
        doNavigate(route, context)
    }

    open func navigate(asyncTo route: Route, context: AnyObject?) async {
        await doAsyncNavigate(route, context)
    }

    open func showAlert(_ alert: Alert) {
        doShowAlert(alert)
    }

    open func showLoadingOverlay(_ state: LoadingOverlayState) {
        doShowLoadingOverlay(state)
    }

    open func showLoadingOverlay(title: String) {
        showLoadingOverlay(LoadingOverlayState(title: title))
    }

    open func hideLoadingOverlay() {
        doHideLoadingOverlay()
    }

    open func start() {
        doStart()
    }
}

// MARK: - Coordinator Extensions

public extension Coordinator {
    /// Wraps this coordinator in an instance of `AnyCoordinator`.
    ///
    /// - Returns: An `AnyCoordinator` instance wrapping this coordinator.
    func asAnyCoordinator() -> AnyCoordinator<Route> {
        AnyCoordinator(self)
    }
}
