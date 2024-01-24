import BitwardenSdk
import Networking

/// A request model for save an attachment to a cipher.
///
struct SaveAttachmentRequest: Request {
    typealias Response = SaveAttachmentResponse

    // MARK: Properties

    /// The body of the request.
    var body: SaveAttachmentRequestModel? { requestModel }

    /// The id of the cipher to update.
    let cipherId: String

    /// The HTTP method for this request.
    let method = HTTPMethod.post

    /// The URL path for this request.
    var path: String { "/ciphers/\(cipherId)/attachment/v2" }

    /// The request details to include in the body of the request.
    let requestModel: SaveAttachmentRequestModel

    // MARK: Initialization

    /// Initialize an `SaveAttachmentRequest`.
    ///
    /// - Parameters:
    ///   - cipherId: The id of the cipher to update.
    ///   - fileName: The name of the attachment.
    ///   - fileSize: The size of the attachment .
    ///   - key: The encryption key for the attachment.
    ///
    init(cipherId: String, fileName: String?, fileSize: Int?, key: String?) {
        self.cipherId = cipherId
        requestModel = SaveAttachmentRequestModel(fileName: fileName, fileSize: fileSize, key: key)
    }
}
