import Foundation
import Networking

// MARK: - SendFileResponseModel

/// A response model received when creating a new File type Send.
///
struct SendFileResponseModel: JSONResponse, Equatable {
    /// The URL where the file associated with this Send should be uploaded.
    let url: URL

    /// The method for uploading the file associated with this Send.
    let fileUploadType: FileUploadType

    /// The new send that was created..
    let sendResponse: SendResponseModel
}
