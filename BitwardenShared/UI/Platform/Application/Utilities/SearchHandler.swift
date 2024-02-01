import UIKit

// MARK: - SearchHandler

/// A protocol to help hand off UISearchResultsUpdating responses a Store.
///
@MainActor
public protocol SearchHandler<State, Action, Effect>: NSObjectProtocol, UISearchResultsUpdating {
    associatedtype Action: Sendable
    associatedtype Effect: Sendable
    associatedtype State: Sendable

    // MARK: Properties

    /// The store for the search handler.
    var store: HandlerStore { get set }
}

public extension SearchHandler {
    /// A store for this SearchHandler
    typealias HandlerStore = Store<State, Action, Effect>
}
