import Networking

// MARK: - SetAccountKeysResponseModel

/// API response model for the `/accounts/keys` endpoint when setting account keys.
///
struct SetAccountKeysResponseModel: Equatable, JSONResponse, AccountKeysResponseModelProtocol {
    // MARK: Properties

    /// The user's account keys.
    let accountKeys: PrivateKeysResponseModel?

    /// The user's key.
    let key: String?

    /// The user's private key.
    @available(*, deprecated, message: "Use accountKeys instead when possible") // TODO: PM-24659 remove
    let privateKey: String?

    /// The user's public key.
    let publicKey: String?
}
