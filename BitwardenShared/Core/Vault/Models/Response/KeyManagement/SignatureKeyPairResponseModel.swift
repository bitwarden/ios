/// API response model for a signature key pair.
///
struct SignatureKeyPairResponseModel: Codable, Equatable {
    /// The wrapped signing key.
    let wrappedSigningKey: WrappedSigningKey

    /// The verifying key.
    let verifyingKey: VerifyingKey
}
