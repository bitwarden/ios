/// API model for an item send.
///
struct SendDataModel: Codable, Equatable {
    // MARK: Properties

    /// The item in the send: the SDK's `Cipher` encoded as a JSON string.
    let data: String?

    /// The encryption version of the item, as the raw value of the SDK's `SendEncryptionType`.
    let encryptionVersion: Int?
}
