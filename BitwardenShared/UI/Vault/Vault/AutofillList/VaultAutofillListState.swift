import BitwardenResources
import BitwardenSdk
import Foundation

// MARK: - VaultAutofillListState

/// An object that defines the current state of a `VaultAutofillListView`.
///
struct VaultAutofillListState: Equatable, Sendable {
    // MARK: Properties

    /// The list of cipher items matching matching the `searchText` grouped in sections, if needed.
    var ciphersForSearch: [VaultListSection] = []

    /// The message to show the user when there are no items.
    var emptyViewMessage: String = Localizations.noItemsTap

    /// The text to be displayed in the button of the empty view.
    var emptyViewButtonText: String = Localizations.newItem

    /// The excluded Fido2 credential id that was found when registering.
    var excludedCredentialIdFound: String?

    /// The group filter.
    var group: VaultListGroup?

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// Whether the extension mode is preparing for autofill from Fido2 list.
    var isAutofillingFido2List: Bool = false

    /// Whether the extension mode is preparing for autofill for text to insert.
    var isAutofillingTextToInsertList: Bool = false

    /// Whether the extension mode is preparing for autofill from Totp items.
    var isAutofillingTotpList: Bool = false

    /// Whether the extension mode is creating a Fido2 credential.
    var isCreatingFido2Credential: Bool = false

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

    /// The list of sections to display for matching vault items.
    var vaultListSections = [VaultListSection]()

    /// Whether to show the add item button.
    var showAddItemButton: Bool {
        !isAutofillingTotpList && !isAutofillingTextToInsertList && excludedCredentialIdFound == nil
    }
}
