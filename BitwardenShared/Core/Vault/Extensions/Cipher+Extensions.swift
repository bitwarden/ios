import BitwardenSdk

extension Cipher {
    // MARK: Methods

    /// Whether the cipher belongs to a group.
    /// - Parameter group: The group to filter.
    /// - Returns: `true` if the cipher belongs to the group, `false` otherwise.
    func belongsToGroup(_ group: VaultListGroup) -> Bool {
        switch group {
        case .card:
            type == .card
        case let .collection(id, _, _):
            collectionIds.contains(id)
        case let .folder(id, _):
            folderId == id
        case .identity:
            type == .identity
        case .login:
            type == .login
        case .noFolder:
            folderId == nil
        case .secureNote:
            type == .secureNote
        case .sshKey:
            type == .sshKey
        case .totp:
            login?.totp != nil
        case .trash:
            deletedDate != nil
        }
    }
}
