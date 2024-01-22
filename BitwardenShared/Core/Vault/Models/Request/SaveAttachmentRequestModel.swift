import Networking

/// API response model for the saving an attachment.
///
struct SaveAttachmentRequestModel: JSONRequestBody, Equatable {
    // MARK: Properties

    /// The attachment's file name.
    let fileName: String?

    /// The attachment's size.
    let fileSize: Double?

    /// The key used to decrypt the attachment.
    let key: String?
}
