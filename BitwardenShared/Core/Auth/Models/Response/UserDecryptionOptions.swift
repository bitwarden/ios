/// API response model for a user's decryption options.
///
struct UserDecryptionOptions: Codable, Equatable, Hashable {
    // MARK: Properties

    /// Whether the current user has a master password that can be used to decrypt their vault.
    var hasMasterPassword: Bool

    /// The user's master password unlock info.
    var masterPasswordUnlock: MasterPasswordUnlockResponseModel?

    /// Details of the user's key connector setup.
    let keyConnectorOption: KeyConnectorUserDecryptionOption?

    /// Details of the user's trust device setup.
    let trustedDeviceOption: TrustedDeviceUserDecryptionOption?

    /// The PRF key set of the WebAuthn login credential that the user logged in with, if the
    /// credential supports PRF.
    var webAuthnPrfOption: WebAuthnPrfUserDecryptionOption?
}

// MARK: - WebAuthnPrfUserDecryptionOption

/// API response model for the PRF key set of a WebAuthn login credential.
///
struct WebAuthnPrfUserDecryptionOption: Codable, Equatable, Hashable {
    /// The private key of the key set, encrypted with the key derived from the PRF output.
    let encryptedPrivateKey: String

    /// The user key, encapsulated with the public key of the key set.
    let encryptedUserKey: String

    /// The base64url encoded ID of the credential.
    let credentialId: String?
}
