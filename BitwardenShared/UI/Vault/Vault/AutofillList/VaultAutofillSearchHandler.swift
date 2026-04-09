import BitwardenKit
import UIKit

// MARK: - VaultAutofillSearchHandler

/// A helper class to bridge `UISearchController`'s  `UISearchResultsUpdating`
///  to the SwiftUI `VaultAutofillListView`.
class VaultAutofillSearchHandler: NSObject {
    // MARK: Properties

    /// The store for this group search handler.
    var store: Store<VaultAutofillListState, VaultAutofillListAction, VaultAutofillListEffect>

    // MARK: Initializers

    /// Initializes the GroupSearchHandler with a given store.
    ///
    /// - Parameter store: The HandlerStore for this SearchHandler.
    ///
    init(store: HandlerStore) {
        self.store = store
    }
}

extension VaultAutofillSearchHandler: SearchHandler {
    func updateSearchResults(for searchController: UISearchController) {
        store.send(.searchStateChanged(isSearching: searchController.isActive))
        store.send(.searchTextChanged(searchController.searchBar.text ?? ""))
    }
}
