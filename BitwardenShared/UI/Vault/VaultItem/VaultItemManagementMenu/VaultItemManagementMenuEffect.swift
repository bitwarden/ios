// MARK: - VaultItemManagementMenuEffect

/// Effects that can be processed by a `AddEditItemProcessor` and `ViewItemProcessor`.
enum VaultItemManagementMenuEffect: Equatable {
    /// The archive option was pressed.
    case archiveItem

    /// The delete option was pressed.
    case deleteItem

    /// The unarchive option was pressed.
    case unarchiveItem
}
