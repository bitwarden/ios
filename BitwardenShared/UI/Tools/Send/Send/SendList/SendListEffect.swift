// MARK: - SendListEffect

/// Effects that can be processed by a `SendListProcessor`.
enum SendListEffect: Equatable {
    /// The add item button was pressed.
    case addItemPressed(SendType)

    /// The view appeared on screen.
    case appeared

    /// The user tapped the dismiss button on the Upgraded to Premium action card.
    case dismissUpgradedToPremiumActionCard

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
