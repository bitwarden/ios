import Foundation

// MARK: - AddItemEffect

/// Effects that can be processed by an `AddItemProcessor`.
enum AddItemEffect {
    /// The check password button was pressed.
    case checkPasswordPressed

    /// The save button was pressed.
    case savePressed

    /// The setup totp button was pressed.
    case setupTotpPressed
}
