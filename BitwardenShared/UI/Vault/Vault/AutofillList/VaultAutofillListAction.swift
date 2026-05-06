import BitwardenKit
import BitwardenSdk

// MARK: - VaultAutofillListAction

/// Actions that can be processed by a `VaultAutofillListProcessor`.
///
enum VaultAutofillListAction: Equatable {
    /// The add button was tapped.
    case addTapped(fromFAB: Bool)

    /// The autofill assist setup button was tapped.
    case autofillAssistSetupTapped

    /// The remove all autofill assist mappings button was tapped.
    case clearAutofillAssistMappingsTapped

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
