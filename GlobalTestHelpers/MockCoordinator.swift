@testable import BitwardenShared

class MockCoordinator<Route>: Coordinator {
    var contexts: [AnyObject?] = []
    var isLoadingOverlayShowing = false
    var isStarted: Bool = false
    var routes: [Route] = []
    var loadingOverlaysShown = [LoadingOverlayState]()

    func hideLoadingOverlay() {
        isLoadingOverlayShowing = false
    }

    func navigate(to route: Route, context: AnyObject?) {
        routes.append(route)
        contexts.append(context)
    }

    func showLoadingOverlay(_ state: LoadingOverlayState) {
        isLoadingOverlayShowing = true
        loadingOverlaysShown.append(state)
    }

    func start() {
        isStarted = true
    }
}
