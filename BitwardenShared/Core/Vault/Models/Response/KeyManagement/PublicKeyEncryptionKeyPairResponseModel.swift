/// API response model for a public key encryption key pair.
///
struct PublicKeyEncryptionKeyPairResponseModel: Codable, Equatable {
    /// The public key.
    let publicKey: String

    /// The signed public key.
    let signedPublicKey: SignedPublicKey?

    /// The wrapped private key.
    let wrappedPrivateKey: WrappedPrivateKey
}
