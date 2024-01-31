import BitwardenSdk
import Networking

// MARK: - DownloadAttachmentRequest

/// Data model for performing a download attachment request.
///
struct DownloadAttachmentRequest: Request {
    typealias Response = DownloadAttachmentResponse

    // MARK: Properties

    /// The id of the attachment.
    var attachmentId: String

    /// The id of the cipher.
    var cipherId: String

    /// The HTTP method for this request.
    let method = HTTPMethod.get

    /// The URL path for this request.
    var path: String {
        "/ciphers/\(cipherId)/attachment/\(attachmentId)"
    }

    // MARK: Initialization

    /// Initialize a `DownloadAttachmentRequest`.
    ///
    /// - Parameters:
    ///   - attachmentId: The id of the attachment to download.
    ///   - cipherId: The id of the cipher that owns the attachment.
    ///
    init(attachmentId: String, cipherId: String) {
        self.attachmentId = attachmentId
        self.cipherId = cipherId
    }
}
