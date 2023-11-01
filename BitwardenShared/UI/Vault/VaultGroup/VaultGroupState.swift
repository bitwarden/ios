import Foundation

// MARK: - VaultGroupState

struct VaultGroupState {
    var group: VaultListGroup = .login
    var items: [VaultListItem] = []
    var searchText: String = ""
}
