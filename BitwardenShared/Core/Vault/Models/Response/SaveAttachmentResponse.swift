import Foundation
import Networking

/// API response for saving an attachment.
///
struct SaveAttachmentResponse: JSONResponse, Codable, Equatable {
    // MARK: Properties

    /// The attachment's identifier.
    let attachmentId: String

    /// The updated cipher model.
    let cipherResponse: CipherDetailsResponseModel

    /// The type of file upload to perform with the file.
    let fileUploadType: FileUploadType

    /// The url of the attachment.
    let url: URL
}
