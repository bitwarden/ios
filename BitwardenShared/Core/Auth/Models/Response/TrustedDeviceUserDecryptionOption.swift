/// API response model for a user's trusted device decryption option.
///
struct TrustedDeviceUserDecryptionOption: Codable, Equatable {
    // MARK: Properties

    /// The user's encrypted private key.
    let encryptedPrivateKey: String?

    /// The user's encrypted key.
    let encryptedUserKey: String?

    /// Whether the user has admin approval.
    let hasAdminApproval: Bool

    /// Whether the user has a login approving device.
    let hasLoginApprovingDevice: Bool

    /// Whether the user has manage reset password permission.
    let hasManageResetPasswordPermission: Bool
}
