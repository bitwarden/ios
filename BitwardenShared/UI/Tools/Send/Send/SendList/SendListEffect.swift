// MARK: - SendListEffect

/// Effects that can be processed by a `SendListProcessor`.
enum SendListEffect {
    /// Any initial data for the view should be loaded.
    case loadData

    /// The send list is being refreshed.
    case refresh

    /// Searches based on the keyword.
    case search(String)

    /// A wrapped `SendListItemRowEffect`.
    case sendListItemRow(SendListItemRowEffect)

    /// Stream the send list for the user.
    case streamSendList
}
