import BitwardenSdk

// MARK: - VaultAutofillListAction

/// Actions that can be processed by a `VaultAutofillListProcessor`.
///
enum VaultAutofillListAction: Equatable {
    /// The add button was tapped.
    case addTapped

    /// The cancel button was tapped.
    case cancelTapped

    /// A forwarded profile switcher action.
    case profileSwitcherAction(ProfileSwitcherAction)

    /// The search bar focus changed.
    ///
    /// - Parameter isSearching: Whether the user is currently searching.
    ///
    case searchStateChanged(isSearching: Bool)

    /// The text in the search bar was changed.
    case searchTextChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
