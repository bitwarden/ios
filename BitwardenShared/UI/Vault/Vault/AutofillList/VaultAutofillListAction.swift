import BitwardenSdk

// MARK: - VaultAutofillListAction

/// Actions that can be processed by a `VaultAutofillListProcessor`.
///
enum VaultAutofillListAction: Equatable {
    /// The add button was tapped.
    case addTapped(fromToolbar: Bool)

    /// The cancel button was tapped.
    case cancelTapped

    /// A forwarded profile switcher action.
    case profileSwitcher(ProfileSwitcherAction)

    /// The text in the search bar was changed.
    case searchStateChanged(isSearching: Bool)

    /// The text in the search bar was changed.
    case searchTextChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
