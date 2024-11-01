/// API model for an SSH key.
///
struct CipherSSHKeyModel: Codable, Equatable {
    // MARK: Properties

    /// The key fingerprint of the SSH key.
    let keyFingerprint: String?

    /// The private key of the SSH key.
    let privateKey: String?

    /// The public key of the SSH key.
    let publicKey: String?
}
