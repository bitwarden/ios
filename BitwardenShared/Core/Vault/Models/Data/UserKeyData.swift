import BitwardenSdk
import Foundation

/// A container for an encrypted user key. Mirrors `BitwardenSdk.LocalUserDataKeyState`.
public struct UserKeyData: Codable, Equatable {
    /// The encrypted representation of the user's encryption key.
    ///
    /// This `EncString` contains the wrapped key that has been encrypted
    /// by `BitwardenSdk`.
    let wrappedKey: EncString

    /// Initializes a new user key data instance with an encrypted wrapped key.
    ///
    /// - Parameter wrappedKey: An `EncString` containing the encrypted user key.
    init(wrappedKey: EncString) {
        self.wrappedKey = wrappedKey
    }

    /// Initializes a new instance from a `LocalUserDataKeyState`.
    ///
    /// - Parameter localUserDataKeyState: A `LocalUserDataKeyState` object containing
    ///   the user's wrapped key.
    init(localUserDataKeyState: LocalUserDataKeyState) {
        self.init(wrappedKey: localUserDataKeyState.wrappedKey)
    }
}
