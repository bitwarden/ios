@testable import BitwardenShared

class MockCoordinator<T>: Coordinator {
    var contexts: [AnyObject?] = []
    var isStarted: Bool = false
    var routes: [T] = []

    func navigate(to route: T, context: AnyObject?) {
        routes.append(route)
        contexts.append(context)
    }

    func start() {
        isStarted = true
    }
}
