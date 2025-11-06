import BitwardenKit
import XCTest

public class MockRouter<Event, Route>: Router {
    public var events = [Event]()
    public var routeForEvent: (Event) -> Route

    public init(routeForEvent: @escaping (Event) -> Route) {
        self.routeForEvent = routeForEvent
    }

    public func handleAndRoute(_ event: Event) async -> Route {
        events.append(event)
        return routeForEvent(event)
    }
}
