// MARK: - ItemListItemRowAction

/// Actions that can be sent from an `ItemListItemRowView`.
enum ItemListItemRowAction: Equatable {
    /// The copy TOTP Code button was pressed.
    case copyTOTPCode(_ code: String)
}
