import Foundation

// MARK: - VaultGroupState

/// The state of a `VaultGroupView`.
struct VaultGroupState: Equatable {
    // MARK: Properties

    /// The `VaultListGroup` being displayed.
    var group: VaultListGroup = .login

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// Whether a collection group is empty.
    var isEmptyCollection: Bool {
        // If the group is a collection
        guard case .collection = group else {
            return false
        }

        // And the collection is empty
        guard loadingState.data != nil else {
            return false
        }

        // Return true
        return true
    }

    /// The current loading state.
    var loadingState: LoadingState<[VaultListItem]> = .loading

    /// The text in the search bar.
    var searchText = ""

    /// Whether to show the special web icons.
    var showWebIcons = true

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The vault filter used to display a single or all vaults for the user.
    let vaultFilterType: VaultFilterType
}
