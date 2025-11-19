// MARK: - UserDecryptionResponseModel

/// API response model for the user's decryption info.
///
struct UserDecryptionResponseModel: Codable, Equatable {
    // MARK: Properties

    /// The user's master password unlock info.
    let masterPasswordUnlock: MasterPasswordUnlockResponseModel?
}
