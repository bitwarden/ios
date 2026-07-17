import Foundation

/// Effects that can be processed by a `ManagePasskeysProcessor`.
///
enum ManagePasskeysEffect: Equatable {
    /// The user tapped the button to delete all stored passkey credentials.
    case deleteAll

    /// The user tapped the button to delete the stored passkey credential with the given
    /// identifier.
    case deleteCredential(id: String)

    /// The view appeared and the stored passkey credentials should be loaded.
    case loadCredentials
}
