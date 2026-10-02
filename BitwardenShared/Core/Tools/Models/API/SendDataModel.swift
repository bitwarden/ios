import BitwardenKit

/// API model for an item send.
///
struct SendDataModel: Codable, Equatable {
    // MARK: Properties

    /// The item in the send: the SDK's `Cipher` encoded as a JSON string.
    let data: String?

    /// The encryption version used for the item's data. Defaults to `.v1` if missing or invalid, and decodes
    /// unrecognized versions as `.unknown`.
    @DefaultValue var encryptionVersion: SendEncryptionVersion
}
