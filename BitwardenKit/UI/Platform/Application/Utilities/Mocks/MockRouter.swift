import BitwardenKit
import XCTest

/// A mock implementation of `Router` for testing purposes.
///
/// This mock records all events passed to `handleAndRoute(_:)` and returns
/// routes based on the provided closure.
public class MockRouter<Event, Route>: Router {
    /// The events that have been handled by this router.
    public var events = [Event]()

    /// A closure that maps events to routes.
    public var routeForEvent: (Event) -> Route

    /// Initialize a mock router with a route mapping closure.
    ///
    /// - Parameter routeForEvent: A closure that determines which route to return for a given event.
    public init(routeForEvent: @escaping (Event) -> Route) {
        self.routeForEvent = routeForEvent
    }

    public func handleAndRoute(_ event: Event) async -> Route {
        events.append(event)
        return routeForEvent(event)
    }
}
