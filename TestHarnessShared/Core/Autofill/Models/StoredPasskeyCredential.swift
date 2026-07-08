import Foundation

// MARK: - StoredPasskeyCredential

/// A passkey credential created via the Test Harness's create passkey flow, persisted so it can
/// later be used to test the assertion/verification flow.
///
struct StoredPasskeyCredential: Codable, Equatable, Identifiable {
    // MARK: Properties

    /// A unique identifier for this credential, derived from its relying party ID and credential ID.
    var id: String { "\(rpId)|\(credentialId.base64EncodedString())" }

    /// The relying party identifier the credential was registered for.
    let rpId: String

    /// The username the credential was registered with.
    let userName: String

    /// The display name the credential was registered with.
    let displayName: String

    /// The credential ID returned by the authorization controller.
    let credentialId: Data

    /// The P-256 public key in ANSI X9.63 format (`0x04 || X || Y`).
    let publicKeyX963: Data

    /// The date the credential was created.
    let createdAt: Date
}
