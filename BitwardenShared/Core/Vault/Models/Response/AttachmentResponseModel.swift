/// API response model for an attachment.
///
struct AttachmentResponseModel: Codable, Equatable {
    // MARK: Properties

    /// The attachment's file name.
    let fileName: String?

    /// The attachment's identifier.
    let id: String?

    /// The key used to decrypt the attachment.
    let key: String?

    /// The response object type.
    let object: String?

    /// The attachment's size.
    let size: Int

    ///
    let sizeName: String?

    /// The attachment's URL.
    let url: String?
}
