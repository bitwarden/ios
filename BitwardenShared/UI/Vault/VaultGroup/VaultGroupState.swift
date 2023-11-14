import Foundation

// MARK: - VaultGroupState

/// The state of a `VaultGroupView`.
struct VaultGroupState: Equatable {
    /// The `VaultListGroup` being displayed.
    var group: VaultListGroup = .login

    /// The items being displayed from this group.
    var items: [VaultListItem] = []

    /// The text in the search bar.
    var searchText: String = ""
}
