import BitwardenSdk
import Networking

// MARK: - DeleteAttachmentRequest

/// Data model for performing a delete attachment request.
///
struct DeleteAttachmentRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The id of the attachment.
    var attachmentId: String

    /// The id of the cipher.
    var cipherId: String

    /// The HTTP method for this request.
    let method = HTTPMethod.delete

    /// The URL path for this request.
    var path: String {
        "/ciphers/\(cipherId)/attachment/\(attachmentId)"
    }

    // MARK: Initialization

    /// Initialize a `DeleteAttachmentRequest`.
    ///
    /// - Parameters:
    ///   - attachmentId: The id of the attachment to delete.
    ///   - cipherId: The id of the cipher that owns the attachment.
    ///
    init(attachmentId: String, cipherId: String) {
        self.attachmentId = attachmentId
        self.cipherId = cipherId
    }
}
