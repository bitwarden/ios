import Foundation

// MARK: - ImportCXPEffect

/// Effects that can be processed by a `ImportCXPProcessor`.
///
enum ImportCXPEffect: Equatable {
    /// The view appeared.
    case appeared

    /// User wants to cancel the import process.
    case cancel

    /// The main button was tapped.
    case mainButtonTapped
}
