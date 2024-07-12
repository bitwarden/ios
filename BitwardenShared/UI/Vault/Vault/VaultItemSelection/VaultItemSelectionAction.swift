import BitwardenSdk

// MARK: - VaultItemSelectionAction

/// Actions that can be processed by a `VaultItemSelectionProcessor`.
///
enum VaultItemSelectionAction: Equatable {
    /// The add button was tapped.
    case addTapped

    /// The cancel button was tapped.
    case cancelTapped

    /// The url has been opened so clear the value in the state.
    case clearURL

    /// A forwarded profile switcher action.
    case profileSwitcher(ProfileSwitcherAction)

    /// The user has started or stopped searching.
    case searchStateChanged(isSearching: Bool)

    /// The text in the search bar was changed.
    case searchTextChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
