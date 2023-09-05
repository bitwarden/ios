@testable import BitwardenShared

class MockCoordinator<Route>: Coordinator {
    var contexts: [AnyObject?] = []
    var isStarted: Bool = false
    var routes: [Route] = []

    func navigate(to route: Route, context: AnyObject?) {
        routes.append(route)
        contexts.append(context)
    }

    func start() {
        isStarted = true
    }
}
