// MARK: - VaultItemManagementMenuAction

/// Actions that can be handled by an `AddEditItemProcessor` and  `ViewItemProcessor`.
enum VaultItemManagementMenuAction: Equatable {
    /// The attachments option was pressed.
    case attachments

    /// The clone option was pressed.
    case clone

    /// The collections option was pressed.
    case editCollections

    /// The generate QR code option was tapped.
    case generateQRCode

    /// The move to organization option was pressed.
    case moveToOrganization
}
