import BitwardenSdk

extension CipherView {
    // MARK: Properties

    /// Whether the cipher is normally hidden for flows by being archived or deleted.
    var isHidden: Bool {
        archivedDate != nil || deletedDate != nil
    }

    // MARK: Methods

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
