import Foundation

// MARK: - CipherLoginFido2Credential

/// API model for a login cipher's FIDO2 credential.
///
struct CipherLoginFido2Credential: Codable, Equatable {
    // MARK: Properties

    /// The signature counter for the credential.
    let counter: String

    /// The creation date and time of the credential.
    let creationDate: Date

    /// The unique identifier of the credential.
    let credentialId: String

    /// Whether the FIDO2 credential is discoverable.
    let discoverable: String

    /// The public key algorithm of the credential.
    let keyAlgorithm: String

    /// The key curve of the credential.
    let keyCurve: String

    /// The type of public key of the credential.
    let keyType: String

    /// The public key of the credential.
    let keyValue: String

    /// The relying party (RP) identity.
    let rpId: String

    /// An optional name of the relying party (RP).
    let rpName: String?

    /// An optional display name of the user associated to the credential.
    let userDisplayName: String?

    /// An optional unique identifier used to identify an account.
    let userHandle: String?

    /// An optional formal name of the user associated to the credential.
    let userName: String?
}
