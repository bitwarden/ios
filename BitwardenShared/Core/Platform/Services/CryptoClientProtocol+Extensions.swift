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
        let kdf: KdfConfig = switch method {
        case .password:
            // Master password unlock should use the master password unlock data's KDF settings if
            // available to support separate KDF settings from the user's auth method.
            account.profile.userDecryptionOptions?.masterPasswordUnlock?.kdf ?? account.kdf
        default:
            account.kdf
        }

        try await initializeUserCrypto(
            req: InitUserCryptoRequest(
                userId: account.profile.userId,
                kdfParams: kdf.sdkKdf,
                email: account.profile.email,
                privateKey: encryptionKeys.encryptedPrivateKey,
                signingKey: encryptionKeys.accountKeys?.signatureKeyPair?.wrappedSigningKey,
                securityState: encryptionKeys.accountKeys?.securityState?.securityState,
                method: method,
            ),
        )
    }
}
