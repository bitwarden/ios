import BitwardenSdk

extension Cipher {
    // MARK: Properties

    /// Whether the cipher is normally hidden for flows by being archived or deleted.
    var isHidden: Bool {
        archivedDate != nil || deletedDate != nil
    }

    // MARK: Methods

    /// Whether the cipher belongs to a group.
    /// - Parameter group: The group to filter.
    /// - Returns: `true` if the cipher belongs to the group, `false` otherwise.
    func belongsToGroup(_ group: VaultListGroup) -> Bool {
        switch group {
        case .archive:
            archivedDate != nil
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

    /// Whether the cipher is normally hidden for flows by being archived or deleted.
    /// This is similar to the above `isHidden` property but taking into consideration
    /// the `FeatureFlag.archiveVaultItems` flag.
    /// 
    /// TODO: PM-30129 When FF gets removed, replace all calls to this function with the above `isHidden` property
    /// and remove this function.
    ///
    /// - Parameter archiveVaultItemsFeatureFlagEnabled: The `FeatureFlag.archiveVaultItems` flag value.
    /// - Returns: `true` if hidden, `false` othewise.
    func isHiddenWithArchiveFF(flag archiveVaultItemsFeatureFlagEnabled: Bool) -> Bool {
        if deletedDate != nil {
            return true
        }

        guard archiveVaultItemsFeatureFlagEnabled else {
            return false
        }

        return archivedDate != nil
    }
}
