import BitwardenKit
import XCTest

@testable import BitwardenShared

enum MockCoordinatorError: Error {
    case alertRouteNotFound
}

class MockCoordinator<Route, Event>: Coordinator {
    var alertShown = [Alert]()
    var alertOnDismissed: (() -> Void)?
    var contexts: [AnyObject?] = []
    var errorAlertsShown = [Error]()
    var errorAlertsWithRetryShown = [(error: Error, retry: () async -> Void)]()
    var events = [Event]()
    var isLoadingOverlayShowing = false
    var isStarted: Bool = false
    var loadingOverlaysShown = [LoadingOverlayState]()
    var toastsShown = [Toast]()
    var routes: [Route] = []

    func handleEvent(_ event: Event, context: AnyObject?) async {
        events.append(event)
        contexts.append(context)
    }

    func hideLoadingOverlay() {
        isLoadingOverlayShowing = false
    }

    func navigate(to route: Route, context: AnyObject?) {
        routes.append(route)
        contexts.append(context)
    }

    func showAlert(_ alert: BitwardenShared.Alert, onDismissed: (() -> Void)?) {
        alertShown.append(alert)
        alertOnDismissed = onDismissed
    }

    func showErrorAlert(error: any Error) async {
        errorAlertsShown.append(error)
    }

    func showErrorAlert(
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

    func showLoadingOverlay(_ state: LoadingOverlayState) {
        isLoadingOverlayShowing = true
        loadingOverlaysShown.append(state)
    }

    func showToast(_ title: String, subtitle: String?, additionalBottomPadding: CGFloat) {
        toastsShown.append(Toast(title: title, subtitle: subtitle))
    }

    func start() {
        isStarted = true
    }
}
