import Foundation

/// Effects that can be processed by a `ManagePasskeysProcessor`.
///
enum ManagePasskeysEffect: Equatable {
    /// Remove all passkey entries from the registry.
    case clearAll

    /// Delete the specified passkey entry from the registry.
    case deletePasskey(PasskeyEntry)

    /// Load the list of registered passkeys from the registry.
    case loadPasskeys
}
