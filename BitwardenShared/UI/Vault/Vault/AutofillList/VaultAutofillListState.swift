import BitwardenSdk
import Foundation

// MARK: - VaultAutofillListState

/// An object that defines the current state of a `VaultAutofillListView`.
///
struct VaultAutofillListState: Equatable {
    // MARK: Properties

    /// The list of matching ciphers that can be used for autofill.
    var ciphersForAutofill: [VaultListItem] = []

    /// The list of cipher items matching matching the `searchText`.
    var ciphersForSearch: [VaultListItem] = []

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState: ProfileSwitcherState = .empty(shouldAlwaysHideAddAccount: true)

    /// The text that the user is currently searching for.
    var searchText = ""

    /// Whether the no search results view should be shown.
    var showNoResults = false

    /// Whether to show the special web icons.
    var showWebIcons = true

    /// A toast message to show in the view.
    var toast: Toast?
}
