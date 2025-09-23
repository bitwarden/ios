// MARK: - MasterPasswordUnlockKdfResponseModel

/// API response model for a user's master password unlock KDF configuration.
///
struct MasterPasswordUnlockKdfResponseModel: Codable, Equatable, Hashable {
    // MARK: Properties

    /// The type of key derivation function algorithm to use.
    let kdfType: KdfType

    /// The number of iterations for the key derivation function.
    let iterations: Int

    /// The memory cost parameter for memory-hard KDF algorithms like Argon2.
    let memory: Int?

    /// The parallelism parameter for KDF algorithms that support parallel computation.
    let parallelism: Int?
}
