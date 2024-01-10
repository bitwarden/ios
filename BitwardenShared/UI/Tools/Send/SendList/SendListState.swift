import BitwardenSdk

// MARK: - SendListState

/// An object that defines the current state of a `SendListView`.
///
struct SendListState {
    /// The text that the user is currently searching for.
    var searchText: String = ""

    /// The sections displayed in the send list.
    var sections: [SendListSection] = []
}
