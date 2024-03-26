// MARK: - VaultListItemRowAction

/// Actions that can be sent from a `VaultListItemRowView`.
enum VaultListItemRowAction: Equatable {
    /// The copy TOTP Code button was pressed.
    case copyTOTPCode(_ code: String)
}
