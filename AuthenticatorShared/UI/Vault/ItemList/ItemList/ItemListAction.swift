import BitwardenKit

// MARK: - ItemListAction

/// Actions that can be processed by a `ItemListProcessor`.
enum ItemListAction: Equatable {
    /// The url has been opened so clear the value in the state.
    case clearURL

    /// The delete item button was pressed.
    ///
    case deletePressed(_ item: ItemListItem)

    /// The edit item button was pressed.
    ///
    case editPressed(_ item: ItemListItem)

    /// An item in the vault group was tapped.
    ///
    /// - Parameter item: The item that was tapped.
    ///
    case itemPressed(_ item: ItemListItem)

    /// The user tapped the go to settings button in the flight recorder banner.
    case navigateToFlightRecorderSettings

    /// The user has started or stopped searching.
    case searchStateChanged(isSearching: Bool)

    /// The text in the search bar was changed.
    case searchTextChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
