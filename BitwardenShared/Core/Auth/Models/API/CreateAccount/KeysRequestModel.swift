// MARK: - KeysRequestModel

/// A model for keys used in the `CreateAccountRequest`.
///
struct KeysRequestModel: Codable, Equatable {
    // MARK: Properties

    /// The public key used in a `CreateAccountRequest`.
    var publicKey: String?

    /// The encrypted private key used in a `CreateAccountRequest`.
    let encryptedPrivateKey: String
}
