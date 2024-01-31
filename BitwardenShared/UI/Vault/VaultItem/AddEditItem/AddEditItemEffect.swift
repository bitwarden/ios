import Foundation

// MARK: - AddEditItemEffect

/// Effects that can be processed by an `AddEditItemProcessor`.
enum AddEditItemEffect {
    /// The view appeared.
    case appeared

    /// The check password button was pressed.
    case checkPasswordPressed

    /// The copy totp button was pressed.
    case copyTotpPressed

    /// The delete option was pressed.
    case deletePressed

    /// Any options that need to be loaded for a cipher (e.g. organizations and folders) should be fetched.
    case fetchCipherOptions

    /// The save button was pressed.
    case savePressed

    /// The setup totp button was pressed.
    case setupTotpPressed
}
