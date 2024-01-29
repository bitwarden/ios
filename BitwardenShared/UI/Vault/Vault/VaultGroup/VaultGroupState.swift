import Foundation

// MARK: - VaultGroupState

/// The state of a `VaultGroupView`.
struct VaultGroupState: Equatable {
    // MARK: Properties

    /// Whether there is data for the vault group.
    var emptyData: Bool = false

    /// The `VaultListGroup` being displayed.
    var group: VaultListGroup = .login

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// The current loading state.
    var loadingState: LoadingState<[VaultListItem]> = .loading {
        didSet {
            emptyData = loadingState.data.isEmptyOrNil ? true : false
        }
    }

    /// The string to use in the empty view.
    var noItemsString: String {
        if showAddItemButton {
            return Localizations.noItems
        } else {
            if case .collection = group {
                return Localizations.noItemsCollection
            }
            if case .trash = group {
                return Localizations.noItemsTrash
            }
        }
        return ""
    }

    /// The text in the search bar.
    var searchText = ""

    /// Whether to show the add item button.
    var showAddItemButton: Bool {
        // If there is no data.
        guard emptyData else { return false }

        // If the group is a collection or trash, return false.
        if case .collection = group {
            return false
        } else if case .trash = group {
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
    let vaultFilterType: VaultFilterType
}
