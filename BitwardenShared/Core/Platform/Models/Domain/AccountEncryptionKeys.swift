import BitwardenSdk

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

    /// Initializes an `AccountEncryptionKeys` from a `WrappedAccountCryptographicState`.
    ///
    /// - Parameters:
    ///   - accountCryptographicState: The SDK's wrapped account cryptographic state.
    ///   - encryptedUserKey: An optional encrypted user key to store alongside the cryptographic state.
    ///
    init(accountCryptographicState: WrappedAccountCryptographicState, encryptedUserKey: String? = nil) {
        switch accountCryptographicState {
        case let .v1(privateKey):
            self.init(
                accountKeys: nil,
                encryptedPrivateKey: privateKey,
                encryptedUserKey: encryptedUserKey,
            )
        case let .v2(privateKey, signedPublicKey, signingKey, securityState):
            self.init(
                accountKeys: PrivateKeysResponseModel(
                    publicKeyEncryptionKeyPair: PublicKeyEncryptionKeyPairResponseModel(
                        publicKey: "", // Not returned by SDK at registration; will populate on next sync.
                        signedPublicKey: signedPublicKey,
                        wrappedPrivateKey: privateKey,
                    ),
                    signatureKeyPair: SignatureKeyPairResponseModel(
                        wrappedSigningKey: signingKey,
                        verifyingKey: "", // Not returned by SDK at registration; will populate on next sync.
                    ),
                    securityState: SecurityStateResponseModel(securityState: securityState),
                ),
                encryptedPrivateKey: privateKey,
                encryptedUserKey: encryptedUserKey,
            )
        }
    }
}
