import Foundation

// MARK: - VaultGroupState

/// The state of a `VaultGroupView`.
struct VaultGroupState: Equatable {
    // MARK: Properties

    /// The `VaultListGroup` being displayed.
    var group: VaultListGroup = .login

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// Is the view searching.
    var isSearching: Bool = false

    /// The current loading state.
    var loadingState: LoadingState<[VaultListItem]> = .loading

    /// The list of organizations the user is a member of.
    var organizations = [Organization]()

    /// An array of results matching the `searchText`.
    var searchResults = [VaultListItem]()

    /// The search vault filter used to display a single or all vaults for the user.
    var searchVaultFilterType: VaultFilterType

    /// The text in the search bar.
    var searchText = ""

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
