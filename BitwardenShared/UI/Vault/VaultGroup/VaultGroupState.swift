import Foundation

// MARK: - VaultGroupState

/// The state of a `VaultGroupView`.
struct VaultGroupState: Equatable {
    // MARK: Types

    /// An enumeration of the possible loading states for the vault group screen.
    enum LoadingState: Equatable {
        /// The view is loading.
        case loading

        /// A set of data that should be displayed on screen.
        case data([VaultListItem])
    }

    // MARK: Properties

    /// The `VaultListGroup` being displayed.
    var group: VaultListGroup = .login

    /// The current loading state.
    var loadingState: LoadingState = .loading

    /// The text in the search bar.
    var searchText: String = ""
}
