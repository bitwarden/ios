import Foundation

// MARK: - VaultGroupState

/// The state of a `VaultGroupView`.
struct VaultGroupState: Equatable, Sendable {
    // MARK: Properties

    /// Whether the vault filter can be shown.
    var canShowVaultFilter = true

    /// Whether there is data for the vault group.
    var emptyData: Bool {
        loadingState.data.isEmptyOrNil
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

    /// Whether to show the add item floating action button.
    var showAddItemFloatingActionButton: Bool {
        switch group {
        case .sshKey, .trash:
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
