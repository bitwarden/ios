/// API response model for a public key encryption key pair.
///
struct PublicKeyEncryptionKeyPairResponseModel: Codable, Equatable {
    /// The wrapped private key.
    let wrappedPrivateKey: WrappedPrivateKey;

    /// The public key.
    let publicKey: UnsignedPublicKey;

    /// The signed public key.
    let signedPublicKey: SignedPublicKey?;
}
