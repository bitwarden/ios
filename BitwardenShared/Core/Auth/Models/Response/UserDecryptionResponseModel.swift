import BitwardenSdk

// MARK: - UserDecryptionResponseModel

/// API response model for the user's decryption info.
///
struct UserDecryptionResponseModel: Codable, Equatable {
    // MARK: Properties

    /// The user's master password unlock info.
    let masterPasswordUnlock: MasterPasswordUnlockResponseModel?

    /// The V2 upgrade token returned when available, allowing vault unlock after V1 → V2 upgrade.
    let v2UpgradeToken: V2UpgradeToken?
}
