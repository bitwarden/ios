// MARK: - KdfConfig

/// A model for configuring KDF options.
///
struct KdfConfig: Encodable, Equatable, KdfConfigProtocol {
    // MARK: Properties

    /// The type of kdf used in the request.
    let kdf: KdfType

    /// The number of kdf iterations performed in the request.
    let kdfIterations: Int

    /// The kdf memory allocated for the computed password hash.
    let kdfMemory: Int?

    /// The number of threads upon which the kdf iterations are performed.
    let kdfParallelism: Int?

    // MARK: Initialization

    /// Initializes a KDF configuration used in the request.
    ///
    /// - Parameters:
    ///   - kdf: The type of kdf used in the request.
    ///   - kdfIterations: The number of kdf iterations performed in the request.
    ///   - kdfMemory: The kdf memory allocated for the computed password hash.
    ///   - kdfParallelism: The number of threads upon which the kdf iterations are performed.
    ///
    init(
        kdf: KdfType = .pbkdf2sha256,
        kdfIterations: Int = Constants.pbkdf2Iterations,
        kdfMemory: Int? = nil,
        kdfParallelism: Int? = nil
    ) {
        self.kdf = kdf
        self.kdfIterations = kdfIterations
        self.kdfMemory = kdfMemory
        self.kdfParallelism = kdfParallelism
    }
}
