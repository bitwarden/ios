/// Domain model that contains the encryption keys for an account.
///
struct AccountEncryptionKeys: Equatable {
    // MARK: Properties

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
        guard let privateKey = identityTokenResponseModel.privateKey else { return nil }
        self.init(
            encryptedPrivateKey: privateKey,
            encryptedUserKey: identityTokenResponseModel.key
        )
    }
}
