import XCTest

@testable import AuthenticatorShared

enum MockCoordinatorError: Error {
    case alertRouteNotFound
}

class MockCoordinator<Route, Event>: Coordinator {
    var alertShown = [Alert]()
    var contexts: [AnyObject?] = []
    var events = [Event]()
    var isLoadingOverlayShowing = false
    var isStarted: Bool = false
    var loadingOverlaysShown = [LoadingOverlayState]()
    var toastsShown = [String]()
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

    func showAlert(_ alert: Alert) {
        alertShown.append(alert)
    }

    func showLoadingOverlay(_ state: LoadingOverlayState) {
        isLoadingOverlayShowing = true
        loadingOverlaysShown.append(state)
    }

    func showToast(_ text: String) {
        toastsShown.append(text)
    }

    func start() {
        isStarted = true
    }
}
