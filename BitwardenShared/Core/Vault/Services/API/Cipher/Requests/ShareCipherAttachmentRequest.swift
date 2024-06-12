import BitwardenSdk
import Foundation
import Networking

/// Errors thrown by `ShareCipherAttachmentRequest`.
///
enum ShareCipherAttachmentRequestError: Error {
    /// The attachment was missing a key.
    case missingAttachmentKey

    /// The attachment was missing an ID.
    case missingAttachmentId
}

/// A request model for sharing a cipher attachment with an organization.
///
struct ShareCipherAttachmentRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The ID of the attachment to share with an organization.
    let attachmentId: String

    /// The body of the request.
    var body: DirectFileUploadRequestModel? {
        requestModel
    }

    /// The ID of the cipher associated with the attachment.
    let cipherId: String

    /// The HTTP method for this request.
    let method = HTTPMethod.post

    /// The URL path for this request.
    var path: String { "/ciphers/\(cipherId)/attachment/\(attachmentId)/share" }

    /// The query items for this request.
    var query: [URLQueryItem] {
        [
            URLQueryItem(name: "organizationId", value: organizationId),
        ]
    }

    /// The request details to include in the body of the request.
    let requestModel: DirectFileUploadRequestModel

    /// The ID of the organization that the attachment is being shared with.
    let organizationId: String

    // MARK: Initialization

    /// Initialize a `ShareCipherAttachmentRequest`.
    ///
    /// - Parameters:
    ///   - attachment: The attachment to share with an organization.
    ///   - attachmentData: The attachment data.
    ///   - cipherId: The ID of the cipher associated with the attachment.
    ///   - date: The date to use to construct the body's `boundary` for this request.
    ///   - organizationId: The ID of the organization that the attachment is being shared with.
    ///
    init(
        attachment: Attachment,
        attachmentData: Data,
        cipherId: String,
        date: Date = .now,
        organizationId: String
    ) throws {
        guard let attachmentId = attachment.id else { throw ShareCipherAttachmentRequestError.missingAttachmentId }
        guard let attachmentKey = attachment.key else { throw ShareCipherAttachmentRequestError.missingAttachmentKey }

        requestModel = DirectFileUploadRequestModel(
            additionalParts: [
                MultipartFormPart(
                    data: Data(attachmentKey.utf8),
                    name: "key"
                ),
            ],
            data: attachmentData,
            date: date,
            fileName: attachment.fileName ?? ""
        )
        self.attachmentId = attachmentId
        self.cipherId = cipherId
        self.organizationId = organizationId
    }
}
