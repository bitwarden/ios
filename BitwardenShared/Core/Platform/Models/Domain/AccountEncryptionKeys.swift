/// Domain model that contains the encryption keys for an account.
///
struct AccountEncryptionKeys: Equatable {
    // MARK: Properties

    /// The user's v2 account keys.
    let accountKeys: PrivateKeysResponseModel?

    /// The encrypted private key for the account.
    let encryptedPrivateKey: String

    /// The encrypted user key for the account.
    let encryptedUserKey: String?
}

extension AccountEncryptionKeys {
    /// Initializes an `AccountEncryptionKeys` from the response of the identity token request.
    ///
    /// - Parameter identityTokenResponseModel: The response model from the identity token request.
    ///
    init?(identityTokenResponseModel: IdentityTokenResponseModel) {
        let privateKey = identityTokenResponseModel.accountKeys?.publicKeyEncryptionKeyPair.wrappedPrivateKey
                            ?? identityTokenResponseModel.privateKey
        guard let privateKey else {
            return nil
        }

        self.init(
            accountKeys: identityTokenResponseModel.accountKeys,
            encryptedPrivateKey: privateKey,
            encryptedUserKey: identityTokenResponseModel.key
        )
    }
}
