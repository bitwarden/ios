import Foundation

// MARK: - ImportCXPEffect

/// Effects that can be processed by a `ImportCXPProcessor`.
///
enum ImportCXPEffect: Equatable {
    /// The view appeared.
    case appeared

    /// User wants to cancel the import process.
    case cancel

    /// Shows the vault after finishing the import process.
    case showVault

    /// User pressed button to start import process.
    case startImport
}
