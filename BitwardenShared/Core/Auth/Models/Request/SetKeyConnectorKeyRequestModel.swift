import Networking

// MARK: - SetKeyConnectorKeyRequestModel

/// API request model for sending a user's key connector key to the API.
///
struct SetKeyConnectorKeyRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The type of kdf for this request.
    let kdf: KdfType

    /// The number of kdf iterations performed in this request.
    let kdfIterations: Int

    /// The kdf memory allocated for the computed password hash.
    let kdfMemory: Int?

    /// The number of threads upon which the kdf iterations are performed.
    let kdfParallelism: Int?

    /// The user's key.
    let key: String

    /// The keys used for this request.
    let keys: KeysRequestModel

    /// The organization's identifier.
    let orgIdentifier: String

    // MARK: Initialization

    /// Initializes a `SetKeyConnectorKeyRequestModel`.
    ///
    /// - Parameters:
    ///   - kdfConfig: The user's KDF options.
    ///   - key: The user's key.
    ///   - keys: The user's keys.
    ///   - orgIdentifier: The organization's identifier.
    ///
    init(kdfConfig: KdfConfig, key: String, keys: KeysRequestModel, orgIdentifier: String) {
        kdf = kdfConfig.kdf
        kdfIterations = kdfConfig.kdfIterations
        kdfMemory = kdfConfig.kdfMemory
        kdfParallelism = kdfConfig.kdfParallelism
        self.key = key
        self.keys = keys
        self.orgIdentifier = orgIdentifier
    }
}
