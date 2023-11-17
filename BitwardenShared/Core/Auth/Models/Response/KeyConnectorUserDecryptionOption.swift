/// API response model for a user's key connector decryption option.
///
struct KeyConnectorUserDecryptionOption: Codable, Equatable, Hashable {
    // MARK: Properties

    /// The URL to the user's key connector.
    let keyConnectorUrl: String
}
