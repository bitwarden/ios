import BitwardenSdk

/// Domain model that contains the encryption keys for an account.
///
struct AccountEncryptionKeys: Equatable {
    // MARK: Properties

    /// The cryptographic state required to initialize the user's vault encryption.
    let cryptographicState: WrappedAccountCryptographicState

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
            cryptographicState: .create(
                accountKeys: responseModel.accountKeys,
                privateKey: privateKey,
            ),
            encryptedUserKey: responseModel.key,
        )
    }
}
