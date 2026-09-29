/// API model for an item send.
///
struct SendDataModel: Codable, Equatable {
    // MARK: Properties

    /// The item in the send: the SDK's `Cipher` encoded as a JSON string.
    let data: String?
}
