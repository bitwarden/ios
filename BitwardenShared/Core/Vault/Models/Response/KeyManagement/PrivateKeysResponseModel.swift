/// API response model for the privately accessible view of an entity (account / org)'s keys.
/// This includes the full key-pairs for public-key encryption and signing, as well as the security state if available.
///
struct PrivateKeysResponseModel: Codable, Equatable {
    /// The public key encryption key pair.
    let publicKeyEncryptionKeyPair: PublicKeyEncryptionKeyPairResponseModel

    /// The signature key pair.
    let signatureKeyPair: SignatureKeyPairResponseModel?

    /// The security state.
    let securityState: SecurityStateResponseModel?
}
