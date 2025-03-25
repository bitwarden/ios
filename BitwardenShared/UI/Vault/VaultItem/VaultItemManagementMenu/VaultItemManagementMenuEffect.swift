// MARK: - VaultItemManagementMenuEffect

/// Effects that can be processed by a `AddEditItemProcessor` and `ViewItemProcessor`.
enum VaultItemManagementMenuEffect: Equatable {
    /// The archive option pressed.
    case archiveItem

    /// The delete option pressed.
    case deleteItem
}
