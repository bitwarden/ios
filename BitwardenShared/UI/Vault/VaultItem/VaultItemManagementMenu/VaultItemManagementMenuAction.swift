// MARK: - VaultItemManagementMenuAction

/// Actions that can be handled by an `AddEditItemProcessor` and  `ViewItemProcessor`.
enum VaultItemManagementMenuAction: Equatable {
    /// The attachments option was pressed.
    case attachments

    /// The move to organization option was pressed.
    case moveToOrganization
}
