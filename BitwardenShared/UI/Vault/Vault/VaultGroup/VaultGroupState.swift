import Foundation

// MARK: - VaultGroupState

/// The state of a `VaultGroupView`.
struct VaultGroupState: Equatable {
    // MARK: Properties

    /// The `VaultListGroup` being displayed.
    var group: VaultListGroup = .login

    /// The current loading state.
    var loadingState: LoadingState<[VaultListItem]> = .loading

    /// The text in the search bar.
    var searchText: String = ""

    /// A toast message to show in the view.
    var toast: Toast?
}
