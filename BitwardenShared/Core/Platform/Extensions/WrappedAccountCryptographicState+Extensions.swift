import BitwardenSdk

/// Extension providing factory methods for creating `WrappedAccountCryptographicState`.
extension WrappedAccountCryptographicState {
    /// Initializes a `WrappedAccountCryptographicState` from the response of an API request that returns a
    /// response with account encryption keys.
    ///
    /// - Parameter responseModel: The API response model that has account encryption keys.
    ///
    init?(responseModel: AccountKeysResponseModelProtocol) {
        let privateKey = responseModel.accountKeys?.publicKeyEncryptionKeyPair.wrappedPrivateKey
            ?? responseModel.privateKey
        guard let privateKey else {
            return nil
        }

        self = .create(accountKeys: responseModel.accountKeys, privateKey: privateKey)
    }

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

    /// Creates a `WrappedAccountCryptographicState` from V2 account keys and a fallback private key.
    ///
    /// Prefers the wrapped private key from `accountKeys` when available. Returns `.v2` if all V2
    /// fields are present, otherwise `.v1`.
    ///
    /// - Parameters:
    ///   - accountKeys: The user's V2 account keys, if available.
    ///   - privateKey: The fallback wrapped private key used when `accountKeys` is `nil`.
    /// - Returns: A `WrappedAccountCryptographicState` with either V1 or V2 data.
    static func create(
        accountKeys: PrivateKeysResponseModel?,
        privateKey: String,
    ) -> WrappedAccountCryptographicState {
        create(
            privateKey: accountKeys?.publicKeyEncryptionKeyPair.wrappedPrivateKey ?? privateKey,
            securityState: accountKeys?.securityState?.securityState,
            signedPublicKey: accountKeys?.publicKeyEncryptionKeyPair.signedPublicKey,
            signingKey: accountKeys?.signatureKeyPair?.wrappedSigningKey,
        )
    }
}
