import BitwardenSdk
import Foundation
import Networking

// MARK: - AddFileSendRequest

/// A request model for adding a new file send.
///
struct AddFileSendRequest: Request {
    // MARK: Types

    typealias Response = SendFileResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: SendRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path = "/sends/file/v2"

    /// The request details to include in the body of the request.
    let requestModel: SendRequestModel

    /// Initialize an `AddFileSendRequest` for a `Send`.
    ///
    /// - Parameters
    ///   - send: The `Send` to add to the user's vault.
    ///   - fileLength: The length of the file.
    ///
    init(send: Send, fileLength: Int) {
        requestModel = SendRequestModel(
            authType: SendAuthType(authType: send.authType),
            deletionDate: send.deletionDate,
            disabled: send.disabled,
            emails: send.emails,
            expirationDate: send.expirationDate,
            file: send.file.map(SendFileModel.init),
            fileLength: fileLength,
            hideEmail: send.hideEmail,
            key: send.key,
            maxAccessCount: send.maxAccessCount.map(Int32.init),
            name: send.name,
            notes: send.notes,
            password: send.password,
            text: nil,
            type: .file,
        )
    }
}
