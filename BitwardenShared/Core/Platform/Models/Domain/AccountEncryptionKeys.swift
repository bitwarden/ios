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
    /// Initializes an `AccountEncryptionKeys` from the response of an API request that returns a response with
    /// account encryption keys.
    ///
    /// - Parameter responseModel: The API response model that has account encryption keys.
    ///
    init?(responseModel: AccountKeysResponseModelProtocol) {
        let privateKey = responseModel.accountKeys?.publicKeyEncryptionKeyPair.wrappedPrivateKey
            ?? responseModel.privateKey
        guard let privateKey else {
            return nil
        }

        self.init(
            accountKeys: responseModel.accountKeys,
            encryptedPrivateKey: privateKey,
            encryptedUserKey: responseModel.key,
        )
    }
}
