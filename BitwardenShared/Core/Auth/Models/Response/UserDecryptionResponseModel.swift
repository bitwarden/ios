// MARK: - UserDecryptionResponseModel

/// API response model for the user's decryption info.
///
struct UserDecryptionResponseModel: Codable, Equatable {
    // MARK: Properties

    /// The user's master password unlock info.
    let masterPasswordUnlock: MasterPasswordUnlockResponseModel?

    /// The hex-encoded ID of the user's current key.
    ///
    /// - Note: `nil` for legacy V1 accounts whose keys carry no key ID.
    let userKeyId: String?
}
