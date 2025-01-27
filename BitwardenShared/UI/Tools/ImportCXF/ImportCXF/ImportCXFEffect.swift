import Foundation

// MARK: - ImportCXFEffect

/// Effects that can be processed by a `ImportCXFProcessor`.
///
enum ImportCXFEffect: Equatable {
    /// The view appeared.
    case appeared

    /// User wants to cancel the import process.
    case cancel

    /// The main button was tapped.
    case mainButtonTapped
}
