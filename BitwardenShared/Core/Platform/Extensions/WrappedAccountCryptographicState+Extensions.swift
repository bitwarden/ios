import BitwardenSdk

/// Extension providing factory methods for creating `WrappedAccountCryptographicState`.
extension WrappedAccountCryptographicState {
    /// Creates a `WrappedAccountCryptographicState` based on the available cryptographic parameters.
    ///
    /// Returns `WrappedAccountCryptographicState.v2` if signing key, signed public key, and security
    /// state are all present, otherwise returns `WrappedAccountCryptographicState.v1`.
    ///
    /// - Parameters:
    ///   - privateKey: The user's wrapped private key.
    ///   - securityState: The user's signed security state (V2 only).
    ///   - signingKey: The user's wrapped signing key (V2 only).
    ///   - signedPublicKey: The user's signed public key (V2 only).
    /// - Returns: A `WrappedAccountCryptographicState` with either V1 or V2 data.
    static func create(
        privateKey: String,
        securityState: String?,
        signedPublicKey: String?,
        signingKey: String?,
    ) -> WrappedAccountCryptographicState {
        if let signingKey,
           let securityState,
           let signedPublicKey {
            .v2(
                privateKey: privateKey,
                signedPublicKey: signedPublicKey,
                signingKey: signingKey,
                securityState: securityState,
            )
        } else {
            .v1(privateKey: privateKey)
        }
    }
}
