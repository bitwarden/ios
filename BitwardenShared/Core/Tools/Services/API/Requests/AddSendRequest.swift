import BitwardenSdk
import Foundation
import Networking

// MARK: - AddSendRequest

/// A request model for adding a new send.
///
struct AddSendRequest: Request {
    // MARK: Types

    typealias Response = SendResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: SendRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    let path = "/sends"

    /// The request details to include in the body of the request.
    let requestModel: SendRequestModel

    /// Initialize an `AddSendRequest` for a `Send`.
    ///
    /// - Parameter send: The `Send` to add to the user's vault.
    ///
    init(send: Send) {
        requestModel = SendRequestModel(
            deletionDate: send.deletionDate,
            disabled: send.disabled,
            expirationDate: send.expirationDate,
            file: send.file.map(SendFileModel.init),
            hideEmail: send.hideEmail,
            key: send.key,
            maxAccessCount: send.maxAccessCount.map(Int32.init),
            name: send.name,
            notes: send.notes,
            password: send.password,
            text: send.text.map(SendTextModel.init)
        )
    }
}
