import BitwardenKit

// MARK: SendListAction

/// Actions that can be processed by a `SendListProcessor`.
///
enum SendListAction: Equatable, Sendable {
    /// Clears the info URL after the web app has been opened.
    case clearInfoUrl

    /// Clears the URL after it has been opened.
    case clearUrl

    /// The info button was pressed.
    case infoButtonPressed

    /// The "Learn more" button on the Upgraded to Premium action card was tapped.
    case learnMoreAboutPremium

    /// The user has started or stopped searching.
    case searchStateChanged(isSearching: Bool)

    /// The text in the search bar was changed.
    case searchTextChanged(String)

    /// A wrapped `SendListItemRowAction`.
    case sendListItemRow(SendListItemRowAction)

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
