import BitwardenSdk

/// Extension for helper functions of `CryptoClientProtocol`.
extension CryptoClientProtocol {
    // MARK: Methods

    /// Initialization method for the user crypto. Needs to be called before any other crypto operations.
    /// - Parameters:
    ///   - account: The account of the user to initialize crypto.
    ///   - encryptionKeys: The encryption keys for the user.
    ///   - method: The crypto initialization method.
    func initializeUserCrypto(
        account: Account,
        encryptionKeys: AccountEncryptionKeys,
        method: InitUserCryptoMethod,
    ) async throws {
        let cryptoState = if let accountKeys = encryptionKeys.accountKeys,
                             let signingKey = accountKeys.signatureKeyPair?.wrappedSigningKey,
                             let securityState = accountKeys.securityState?.securityState {
            WrappedAccountCryptographicState
                .v2(
                    privateKey: encryptionKeys.encryptedPrivateKey,
                    signedPublicKey: accountKeys.publicKeyEncryptionKeyPair.signedPublicKey,
                    signingKey: signingKey,
                    securityState: securityState,
                )
        } else {
            WrappedAccountCryptographicState
                .v1(
                    privateKey: encryptionKeys.encryptedPrivateKey
                )
        }
        try await initializeUserCrypto(
            req: InitUserCryptoRequest(
                userId: account.profile.userId,
                kdfParams: account.kdf.sdkKdf,
                email: account.profile.email,
                accountCryptographicState: cryptoState,
                method: method,
            ),
        )
    }
}
