/// API request model for an attachment.
///
struct AttachmentRequestModel: Codable, Equatable {
    // MARK: Properties

    /// The attachment's file name.
    let fileName: String?

    /// The key used to decrypt the attachment.
    let key: String?

    /// The attachment's size.
    let size: String?
}
