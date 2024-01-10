// MARK: - SearchVaultFilterRowAction

/// Actions that can be handled by `VaultListProcessor`.
enum SearchVaultFilterRowAction: Equatable {
    /// The selected vault filter for search changed.
    case searchVaultFilterChanged(VaultFilterType)
}
