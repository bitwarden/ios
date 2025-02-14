import Foundation

// MARK: - VaultGroupState

/// The state of a `VaultGroupView`.
struct VaultGroupState: Equatable, Sendable {
    // MARK: Types

    /// The type of floating action button to display in the view.
    ///
    enum FloatingActionButtonType: Equatable {
        /// The standard floating action button which performs an action on tap.
        case button

        /// A floating action button which displays a menu.
        case menu
    }

    // MARK: Properties

    /// Whether the vault filter can be shown.
    var canShowVaultFilter = true

    /// Whether there is data for the vault group.
    var emptyData: Bool {
        loadingState.data.isEmptyOrNil
    }

    /// The type of floating action button to display based on which group type is shown.
    var floatingActionButtonType: FloatingActionButtonType? {
        switch group {
        case .card, .identity, .login, .secureNote:
            return .button
        case .collection, .folder, .noFolder:
            return .menu
        case .sshKey, .totp, .trash:
            return nil
        }
    }

    /// The `VaultListGroup` being displayed.
    var group: VaultListGroup = .login

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// Whether the policy is enforced to disable personal vault ownership.
    var isPersonalOwnershipDisabled: Bool = false

    /// Is the view searching.
    var isSearching: Bool = false

    /// The current loading state.
    var loadingState: LoadingState<[VaultListSection]> = .loading(nil)

    /// The string to use in the empty view.
    var noItemsString: String {
        switch group {
        case .collection:
            return Localizations.noItemsCollection
        case .folder:
            return Localizations.noItemsFolder
        case .trash:
            return Localizations.noItemsTrash
        default:
            return Localizations.noItems
        }
    }

    /// The list of organizations the user is a member of.
    var organizations = [Organization]()

    /// An array of results matching the `searchText`.
    var searchResults = [VaultListItem]()

    /// The text in the search bar.
    var searchText = ""

    /// The search vault filter used to display a single or all vaults for the user.
    var searchVaultFilterType = VaultFilterType.allVaults

    /// Whether to show the add item button in the view.
    var showAddItemButton: Bool {
        // Don't show if there is data.
        guard emptyData else { return false }

        switch group {
        case .collection, .sshKey, .trash:
            return false
        default:
            return true
        }
    }

    /// Whether to show the special web icons.
    var showWebIcons = true

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The state for showing the vault filter.
    var vaultFilterState: SearchVaultFilterRowState {
        SearchVaultFilterRowState(
            canShowVaultFilter: canShowVaultFilter,
            isPersonalOwnershipDisabled: isPersonalOwnershipDisabled,
            organizations: organizations,
            searchVaultFilterType: searchVaultFilterType
        )
    }

    /// The vault filter used to display a single or all vaults for the user.
    let vaultFilterType: VaultFilterType
}
