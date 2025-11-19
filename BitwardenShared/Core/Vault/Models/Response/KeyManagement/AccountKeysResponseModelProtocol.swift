/// Protocol for API response models which have user's account keys.
protocol AccountKeysResponseModelProtocol {
    /// The user's account keys.
    var accountKeys: PrivateKeysResponseModel? { get } // TODO: PM-24659 Make it non-optional when server ready.

    /// The user's key.
    var key: String? { get }

    /// The user's private key.
    @available(*, deprecated, message: "Use accountKeys instead when possible") // TODO: PM-24659 remove
    var privateKey: String? { get }
}
