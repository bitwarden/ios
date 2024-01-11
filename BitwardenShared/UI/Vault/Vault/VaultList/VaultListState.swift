import Foundation

// MARK: - VaultListState

/// An object that defines the current state of a `VaultListView`.
///
struct VaultListState: Equatable {
    // MARK: Properties

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// The loading state of the My Vault screen.
    var loadingState: LoadingState<[VaultListSection]> = .loading

    /// The list of organizations the user is a member of.
    var organizations = [Organization]()

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState: ProfileSwitcherState = .empty()

    /// An array of results matching the `searchText`.
    var searchResults = [VaultListItem]()

    /// The text that the user is currently searching for.
    var searchText = ""

    /// Whether to show the special web icons.
    var showWebIcons = true

    /// The search vault filter used to display a single or all vaults for the user.
    var searchVaultFilterType: VaultFilterType = .allVaults

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The vault filter used to display a single or all vaults for the user.
    var vaultFilterType: VaultFilterType = .allVaults

    // MARK: Computed Properties

    /// The navigation title for the view.
    var navigationTitle: String {
        if organizations.isEmpty {
            Localizations.myVault
        } else {
            Localizations.vaults
        }
    }

    /// The user's initials.
    var userInitials: String {
        profileSwitcherState.activeAccountInitials
    }
}
