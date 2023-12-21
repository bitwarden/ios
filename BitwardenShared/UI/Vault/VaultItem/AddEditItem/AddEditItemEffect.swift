import Foundation

// MARK: - AddEditItemEffect

/// Effects that can be processed by an `AddEditItemProcessor`.
enum AddEditItemEffect {
    /// The check password button was pressed.
    case checkPasswordPressed

    /// The copy totp button was pressed.
    case copyTotpPressed

    /// The delete option was pressed.
    case deletePressed

    /// The save button was pressed.
    case savePressed

    /// The setup totp button was pressed.
    case setupTotpPressed
}
