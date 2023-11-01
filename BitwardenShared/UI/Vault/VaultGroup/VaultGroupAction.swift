// MARK: - VaultGroupAction

enum VaultGroupAction: Equatable {
    case addItemPressed
    case itemPressed(VaultListItem)
    case morePressed(VaultListItem)
    case searchTextChanged(String)
}
