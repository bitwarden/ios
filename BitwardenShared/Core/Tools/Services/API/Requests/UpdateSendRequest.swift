import BitwardenSdk
import Foundation
import Networking

// MARK: - UpdateSendRequest

/// A request model for updating an existing send.
///
struct UpdateSendRequest: Request {
    // MARK: Types

    typealias Response = SendResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: SendRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method: HTTPMethod = .put

    /// The URL path for this request.
    var path: String { "/sends/\(sendId)" }

    /// The request details to include in the body of the request.
    let requestModel: SendRequestModel

    /// The id of the send that is being updated.
    let sendId: String

    /// Initialize an `UpdateSendRequest` for a `Send`.
    ///
    /// - Parameter send: The `Send` to add to the user's vault.
    /// - Throws: An `UpdateSendRequestError` if an error is encountered when creating this request.
    ///
    init(send: Send) throws {
        guard let id = send.id else {
            throw BitwardenError.dataError("Received a send from the API with a missing ID.")
        }
        requestModel = SendRequestModel(
            authType: SendAuthType(authType: send.authType),
            deletionDate: send.deletionDate,
            disabled: send.disabled,
            emails: send.emails,
            expirationDate: send.expirationDate,
            file: send.file.map(SendFileModel.init),
            hideEmail: send.hideEmail,
            key: send.key,
            maxAccessCount: send.maxAccessCount.map(Int32.init),
            name: send.name,
            notes: send.notes,
            password: send.password,
            text: send.text.map(SendTextModel.init),
            type: SendType(sendType: send.type),
        )
        sendId = id
    }
}
