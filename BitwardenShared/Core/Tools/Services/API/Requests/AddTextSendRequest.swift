import BitwardenSdk
import Foundation
import Networking

// MARK: - AddTextSendRequest

/// A request model for adding a new send.
///
struct AddTextSendRequest: Request {
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

    /// Initialize an `AddTextSendRequest` for a `Send`.
    ///
    /// - Parameter send: The `Send` to add to the user's vault.
    ///
    init(send: Send) {
        requestModel = SendRequestModel(
            authType: SendAuthType(authType: send.authType),
            deletionDate: send.deletionDate,
            disabled: send.disabled,
            emails: send.emails,
            expirationDate: send.expirationDate,
            file: nil,
            hideEmail: send.hideEmail,
            key: send.key,
            maxAccessCount: send.maxAccessCount.map(Int32.init),
            name: send.name,
            notes: send.notes,
            password: send.password,
            text: send.text.map(SendTextModel.init),
            type: .text,
        )
    }
}
