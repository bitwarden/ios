import Foundation

// MARK: - ImportCXPRoute

/// A route to specific screens in the Credential Exhange import flow.
public enum ImportCXPRoute: Equatable, Hashable {
    /// A route to dismiss the screen currently presented modally.
    case dismiss

    /// A route to begin importing using Credential Exchange protocol.
    /// - Parameter: The `credentialImportToken` to use in the import manager.
    case importCredentials(credentialImportToken: UUID)
}
