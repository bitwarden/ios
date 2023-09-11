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

    /// The attachment's size.
    let size: String?

    /// The human-readable string of the file size.
    let sizeName: String?

    /// The attachment's URL.
    let url: String?
}
