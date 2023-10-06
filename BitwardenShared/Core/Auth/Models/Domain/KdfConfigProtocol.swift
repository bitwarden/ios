import BitwardenSdk

// MARK: KdfConfigProtocol

/// A protocol for a type that provides configuration information for the kdf algorithm. Typically response models
/// will conform to this protocol, to allow for easily generating a `BitwardenSdk.Kdf` object for interaction with
/// the SDK.
///
protocol KdfConfigProtocol {
    // MARK: Properties

    /// The type of KDF algorithm to use.
    var kdf: KdfType { get }

    /// The number of iterations to use when calculating a password hash.
    var kdfIterations: Int { get }

    /// The amount of memory to use when calculating a password hash.
    var kdfMemory: Int? { get }

    /// The number of threads to use when calculating a password hash.
    var kdfParallelism: Int? { get }
}

extension KdfConfigProtocol {
    /// Create an equivalent `BitwardenSdk.Kdf` representation of this kdf configuration. This result can be used to
    /// interact with the SDK.
    ///
    /// Note: When creating an `.argon2id` value, default values will be used for memory and/or parallelism if they
    /// are not provided by this object.
    var sdkKdf: BitwardenSdk.Kdf {
        switch kdf {
        case .argon2id:
            return .argon2id(
                iterations: NonZeroU32(kdfIterations),
                memory: NonZeroU32(kdfMemory ?? Constants.kdfArgonMemory),
                parallelism: NonZeroU32(kdfParallelism ?? Constants.kdfArgonParallelism)
            )
        case .pbkdf2sha256:
            return .pbkdf2(
                iterations: NonZeroU32(kdfIterations)
            )
        }
    }
}
