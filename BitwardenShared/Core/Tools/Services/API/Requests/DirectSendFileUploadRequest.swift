import Foundation
import Networking

// MARK: - DirectSendFileUploadRequest

/// A request for uploading a send file directly.
///
struct DirectSendFileUploadRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of the request.
    var body: DirectFileUploadRequestModel? {
        requestModel
    }

    /// The id of the file being uploaded.
    let fileId: String

    /// The URL path for this request that will be appended to the base URL.
    var path: String {
        "/sends/\(sendId)/file/\(fileId)"
    }

    /// The HTTP method for the request.
    let method: HTTPMethod = .post

    /// The request details to include in the body of the request.
    let requestModel: DirectFileUploadRequestModel

    /// The id of the Send associated with this file.
    let sendId: String

    // MARK: Initialization

    /// Creates a new `DirectSendFileUploadRequest`.
    ///
    /// - Parameters:
    ///   - data: The data representation of the file.
    ///   - fileName: The name of the file.
    ///   - fileId: The id of the file.
    ///   - sendId: The id of the Send.
    ///
    init(
        data: Data,
        fileName: String,
        fileId: String,
        sendId: String
    ) {
        self.fileId = fileId
        requestModel = DirectFileUploadRequestModel(
            data: data,
            fileName: fileName
        )
        self.sendId = sendId
    }
}
