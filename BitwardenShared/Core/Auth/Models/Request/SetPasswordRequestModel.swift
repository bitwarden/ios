import Networking

// MARK: - SetPasswordRequestModel

/// API request model for settings a user's password.
///
struct SetPasswordRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The type of KDF for this request.
    let kdf: KdfType?

    /// The number of KDF iterations performed in this request.
    let kdfIterations: Int?

    /// The KDF memory allocated for the computed password hash.
    let kdfMemory: Int?

    /// The number of threads upon which the KDF iterations are performed.
    let kdfParallelism: Int?

    /// The encrypted user key.
    let key: String

    /// The user's encryption keys.
    let keys: KeysRequestModel?

    /// The master password hash used to authenticate a user.
    let masterPasswordHash: String

    /// The master password hint.
    let masterPasswordHint: String?

    /// The organization's identifier.
    let orgIdentifier: String

    // MARK: Initialization

    /// Initialize a `SetPasswordRequestModel`.
    ///
    /// - Parameters:
    ///   - kdfConfig: The KDF configuration options.
    ///   - key: The encrypted user key.
    ///   - keys: The user's encryption keys.
    ///   - masterPasswordHash: The master password hash used to authenticate a user.
    ///   - masterPasswordHint: The master password hint.
    ///   - orgIdentifier: The organization's identifier.
    ///
    init(
        kdfConfig: KdfConfig,
        key: String,
        keys: KeysRequestModel?,
        masterPasswordHash: String,
        masterPasswordHint: String?,
        orgIdentifier: String
    ) {
        kdf = kdfConfig.kdf
        kdfIterations = kdfConfig.kdfIterations
        kdfMemory = kdfConfig.kdfMemory
        kdfParallelism = kdfConfig.kdfParallelism
        self.key = key
        self.keys = keys
        self.masterPasswordHash = masterPasswordHash
        self.masterPasswordHint = masterPasswordHint
        self.orgIdentifier = orgIdentifier
    }
}
