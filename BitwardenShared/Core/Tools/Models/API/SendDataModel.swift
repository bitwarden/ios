/// API model for an item send.
///
struct SendDataModel: Codable, Equatable {
    // MARK: Properties

    /// The item in the send: an opaque sealed cipher blob produced by the SDK.
    let data: String?

    /// The encryption version of the item, as the raw value of the SDK's `SendEncryptionType`.
    let encryptionVersion: Int?

    /// The unencrypted metadata of the item.
    var metadata: SendItemMetadataModel?
}

// MARK: - SendItemMetadataModel

/// API model for the unencrypted metadata of an item send.
///
struct SendItemMetadataModel: Codable, Equatable {
    // MARK: Properties

    /// The ID of the vault item being sent.
    let itemId: String
}
