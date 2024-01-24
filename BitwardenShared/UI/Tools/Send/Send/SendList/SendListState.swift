import Foundation

// MARK: - SendListState

/// An object that defines the current state of a `SendListView`.
///
struct SendListState {
    /// The info URL to open.
    var infoUrl: URL?

    /// The text that the user is currently searching for.
    var searchText: String = ""

    /// An array of results matching the ``searchText``.
    var searchResults: [SendListItem] = []

    /// The sections displayed in the send list.
    var sections: [SendListSection] = []

    /// A toast message to show in the view.
    var toast: Toast?
}
