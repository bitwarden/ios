import XCTest

@testable import BitwardenShared

enum MockCoordinatorError: Error {
    case alertRouteNotFound
}

class MockCoordinator<Route, Event>: Coordinator {
    var alertShown = [Alert]()
    var alertOnDismissed: (() -> Void)?
    var contexts: [AnyObject?] = []
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

    func showLoadingOverlay(_ state: LoadingOverlayState) {
        isLoadingOverlayShowing = true
        loadingOverlaysShown.append(state)
    }

    func showToast(_ title: String, subtitle: String?) {
        toastsShown.append(Toast(title: title, subtitle: subtitle))
    }

    func start() {
        isStarted = true
    }
}
