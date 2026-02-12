import Foundation

// MARK: - AddEditItemEffect

/// Effects that can be processed by an `AddEditItemProcessor`.
enum AddEditItemEffect {
    /// The view appeared.
    case appeared

    /// The archived button was pressed.
    case archivedPressed

    /// The check password button was pressed.
    case checkPasswordPressed

    /// The copy totp button was pressed.
    case copyTotpPressed

    /// The delete option was pressed.
    case deletePressed

    /// The user tapped the dismiss button on the new login action card.
    case dismissNewLoginActionCard

    /// Any options that need to be loaded for a cipher (e.g. organizations and folders) should be fetched.
    case fetchCipherOptions

    /// The save button was pressed.
    case savePressed

    /// The setup totp button was pressed.
    case setupTotpPressed

    /// Show the learn new login guided tour.
    case showLearnNewLoginGuidedTour

    /// Stream the cipher details.
    case streamCipherDetails

    /// Stream the list of folders in the vault.
    case streamFolders

    /// The unarchive button was pressed.
    case unarchivePressed
}
