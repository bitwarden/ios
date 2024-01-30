import XCTest

@testable import BitwardenShared

class MockRouter<Event, Route>: Router {
    var events = [Event]()
    var routeForEvent: (Event) -> Route

    init(routeForEvent: @escaping (Event) -> Route) {
        self.routeForEvent = routeForEvent
    }

    func handleAndRoute(_ event: Event) async -> Route {
        events.append(event)
        return routeForEvent(event)
    }
}
