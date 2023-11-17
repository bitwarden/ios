/// API response model for a user's decryption options.
///
struct UserDecryptionOptions: Codable, Equatable, Hashable {
    // MARK: Properties

    /// Whether the current user has a master password that can be used to decrypt their vault.
    let hasMasterPassword: Bool

    /// Details of the user's key connector setup.
    let keyConnectorOption: KeyConnectorUserDecryptionOption?

    /// Details of the user's trust device setup.
    let trustedDeviceOption: TrustedDeviceUserDecryptionOption?
}
