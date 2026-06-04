// MARK: - KeyConnectorConversionResult

/// The keys returned after converting a new user to Key Connector, used to immediately unlock the vault.
///
struct KeyConnectorConversionResult {
    /// The encrypted user key, wrapped with the master key.
    let encryptedUserKey: String

    /// The master key stored on Key Connector, used as the unlock mechanism.
    let masterKey: String
}
