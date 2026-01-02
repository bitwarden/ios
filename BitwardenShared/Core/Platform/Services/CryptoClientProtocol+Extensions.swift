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
        let accountCryptographicState = WrappedAccountCryptographicState.create(
            privateKey: encryptionKeys.encryptedPrivateKey,
            securityState: encryptionKeys.accountKeys?.securityState?.securityState,
            signedPublicKey: encryptionKeys.accountKeys?.signatureKeyPair?.verifyingKey,
            signingKey: encryptionKeys.accountKeys?.signatureKeyPair?.wrappedSigningKey,
        )

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
