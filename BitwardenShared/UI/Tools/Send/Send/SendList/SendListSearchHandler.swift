import UIKit

// MARK: - SendListSearchHandler

/// A helper class to bridge `UISearchController`'s  `UISearchResultsUpdating`
///  to the SwiftUI `VaultGroupView`.
class SendListSearchHandler: NSObject {
    // MARK: Properties

    /// The store for this group search handler.
    var store: Store<SendListState, SendListAction, SendListEffect>

    // MARK: Initializers

    /// Initializes the SendListSearchHandler with a given store.
    ///
    /// - Parameter store: The HandlerStore for this SearchHandler.
    ///
    init(store: HandlerStore) {
        self.store = store
    }
}

extension SendListSearchHandler: SearchHandler {
    func updateSearchResults(for searchController: UISearchController) {
        store.send(
            .searchTextChanged(
                searchController.searchBar.text ?? ""
            )
        )
    }
}
