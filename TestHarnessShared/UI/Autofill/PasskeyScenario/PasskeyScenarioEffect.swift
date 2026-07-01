import Foundation

/// Effects that can be processed by a `PasskeyScenarioProcessor`.
///
enum PasskeyScenarioEffect: Equatable {
    /// The user tapped Sign In with Passkey.
    case assertPasskey

    /// Remove all passkey entries from the registry.
    case clearAll

    /// Delete the specified passkey entry from the registry.
    case deletePasskey(PasskeyEntry)

    /// Load the list of registered passkeys from the registry.
    case loadPasskeys

    /// The user tapped Register Passkey.
    case registerPasskey
}
