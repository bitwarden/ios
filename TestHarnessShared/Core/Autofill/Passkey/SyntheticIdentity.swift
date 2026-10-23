import Foundation

// MARK: - SyntheticIdentity

/// The synthetic, throwaway identity used to bootstrap the passkey scenarios' ephemeral
/// `BitwardenSdk.Client`. Persisted in the keychain so the same crypto keys can be reconstructed
/// across app launches.
///
struct SyntheticIdentity: Codable, Equatable {
    /// The synthetic account's email address.
    let email: String

    /// The master-key-wrapped user key returned when the identity's keys were generated.
    let encryptedUserKey: String

    /// The number of PBKDF2 iterations used to derive this identity's keys.
    let kdfIterations: UInt32

    /// The synthetic account's master password.
    let password: String

    /// The synthetic account's wrapped private key.
    let privateKey: String

    /// The synthetic account's user ID.
    let userId: String
}
