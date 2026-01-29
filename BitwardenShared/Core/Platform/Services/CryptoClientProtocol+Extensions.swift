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
        let accountCryptographicState: WrappedAccountCryptographicState;
        if encryptionKeys.accountKeys == nil {
            // V1 Account Encryption
            //
            // Try accountKeys first, fallback to encryptedPrivateKey
            // encryptedPrivateKey will be removed in future versions
            let v1PrivateKey = encryptionKeys.accountKeys?.publicKeyEncryptionKeyPair.wrappedPrivateKey ?? encryptionKeys.encryptedPrivateKey
            accountCryptographicState = WrappedAccountCryptographicState.create(
                privateKey: v1PrivateKey,
                securityState: nil,
                signedPublicKey: nil,
                signingKey: nil
            )
        } else {
            // V2 Account Encryption
            accountCryptographicState = WrappedAccountCryptographicState.create(
                privateKey: encryptionKeys.accountKeys?.publicKeyEncryptionKeyPair.wrappedPrivateKey,
                securityState: encryptionKeys.accountKeys?.securityState?.securityState,
                signedPublicKey: encryptionKeys.accountKeys?.publicKeyEncryptionKeyPair.signedPublicKey,
                signingKey: encryptionKeys.accountKeys?.signatureKeyPair?.wrappedSigningKey
            )
        }

        try await initializeUserCrypto(
            req: InitUserCryptoRequest(
                userId: account.profile.userId,
                kdfParams: account.kdf.sdkKdf,
                email: account.profile.email,
                accountCryptographicState: accountCryptographicState,
                method: method,
            ),
        )
    }
}
