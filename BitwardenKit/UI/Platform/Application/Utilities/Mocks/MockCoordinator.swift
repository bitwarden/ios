import BitwardenKit
import XCTest

public enum MockCoordinatorError: Error {
    case alertRouteNotFound
}

public class MockCoordinator<Route, Event>: Coordinator {
    public var alertShown = [BitwardenKit.Alert]()
    public var alertOnDismissed: (() -> Void)?
    public var contexts: [AnyObject?] = []
    public var errorAlertsShown = [Error]()
    public var errorAlertsWithRetryShown = [(error: Error, retry: () async -> Void)]()
    public var events = [Event]()
    public var isLoadingOverlayShowing = false
    public var isStarted: Bool = false
    public var loadingOverlaysShown = [LoadingOverlayState]()
    public var toastsShown = [Toast]()
    public var routes: [Route] = []

    public init() {}

    public func handleEvent(_ event: Event, context: AnyObject?) async {
        events.append(event)
        contexts.append(context)
    }

    public func hideLoadingOverlay() {
        isLoadingOverlayShowing = false
    }

    public func navigate(to route: Route, context: AnyObject?) {
        routes.append(route)
        contexts.append(context)
    }

    public func showAlert(_ alert: BitwardenKit.Alert, onDismissed: (() -> Void)?) {
        alertShown.append(alert)
        alertOnDismissed = onDismissed
    }

    public func showErrorAlert(error: any Error) async {
        errorAlertsShown.append(error)
    }

    public func showErrorAlert(
        error: any Error,
        tryAgain: (() async -> Void)?,
        onDismissed: (() -> Void)?,
    ) async {
        if let tryAgain {
            errorAlertsWithRetryShown.append((error, tryAgain))
        } else {
            errorAlertsShown.append(error)
        }
        alertOnDismissed = onDismissed
    }

    public func showLoadingOverlay(_ state: LoadingOverlayState) {
        isLoadingOverlayShowing = true
        loadingOverlaysShown.append(state)
    }

    public func showToast(_ title: String, subtitle: String?, additionalBottomPadding: CGFloat) {
        toastsShown.append(Toast(title: title, subtitle: subtitle))
    }

    public func start() {
        isStarted = true
    }
}
