import Foundation

// MARK: - VaultGroupState

/// The state of a `VaultGroupView`.
struct VaultGroupState: Equatable {
    // MARK: Properties

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
    var loadingState: LoadingState<[VaultListItem]> = .loading

    /// The string to use in the empty view.
    var noItemsString: String {
        switch group {
        case .collection:
            return Localizations.noItemsCollection
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
    var searchVaultFilterType: VaultFilterType

    /// Whether to show the add item button in the view.
    var showAddItemButton: Bool {
        // Don't show if there is data.
        guard emptyData else { return false }

        // If the collection or trash are empty, return false.
        if case .collection = group {
            return false
        } else if case .trash = group {
            return false
        }
        return true
    }

    /// Whether to show the add item button in the toolbar.
    var showAddToolbarItem: Bool {
        if case .trash = group {
            return false
        }
        return true
    }

    /// Whether to show the special web icons.
    var showWebIcons = true

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The vault filter used to display a single or all vaults for the user.
    var vaultFilterType: VaultFilterType

    // MARK: Computed Properties

    /// The accessibility ID for the filter row.
    var filterAccessibilityID: String {
        switch group {
        case .card:
            return "CardFilter"
        case .identity:
            return "IdentityFilter"
        case .login:
            return "LoginFilter"
        case .secureNote:
            return "SecureNoteFilter"
        case .totp:
            return ""
        case .collection:
            return "CollectionFilter"
        case .folder:
            return "FolderFilter"
        case .trash:
            return "TrashFilter"
        }
    }
}
