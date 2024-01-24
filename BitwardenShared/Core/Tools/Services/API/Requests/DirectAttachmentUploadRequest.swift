import Foundation
import Networking

// MARK: - DirectAttachmentUploadRequest

/// A request for uploading an attachment file directly.
///
struct DirectAttachmentUploadRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The id of the attachment being uploaded.
    let attachmentId: String

    /// The body of the request.
    var body: DirectFileUploadRequestModel? {
        requestModel
    }

    /// The id of the cipher associated with this attachment.
    let cipherId: String

    /// The URL path for this request that will be appended to the base URL.
    var path: String {
        "/ciphers/\(cipherId)/attachment/\(attachmentId)"
    }

    /// The HTTP method for the request.
    let method: HTTPMethod = .post

    /// The request details to include in the body of the request.
    let requestModel: DirectFileUploadRequestModel

    // MARK: Initialization

    /// Creates a new `DirectAttachmentUploadRequest`.
    ///
    /// - Parameters:
    ///   - attachmentId: The id of the attachment.
    ///   - cipherId: The id of the cipher.
    ///   - data: The data representation of the attachment.
    ///   - fileName: The name of the attachment.
    ///
    init(
        attachmentId: String,
        data: Data,
        cipherId: String,
        fileName: String
    ) {
        self.attachmentId = attachmentId
        self.cipherId = cipherId
        requestModel = DirectFileUploadRequestModel(
            data: data,
            fileName: fileName
        )
    }
}
