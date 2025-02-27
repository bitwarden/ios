// MARK: - Router

/// A protocol for an object that configures state for a given event and outputs a redirected route.
@MainActor
public protocol Router<Event, Route>: AnyObject {
    associatedtype Event
    associatedtype Route

    /// Prepare the coordinator for a given route and redirect if needed.
    ///
    /// - Parameter route: The route for which the coordinator should prepare itself.
    /// - Returns: A redirected route for which the Coordinator is prepared.
    ///
    func handleAndRoute(_ event: Event) async -> Route
}
