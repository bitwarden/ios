import Foundation
import Networking

// MARK: - DeleteAccountRequest

/// The API request sent when deleting an account.
///
struct DeleteAccountRequest: Request {
    typealias Response = EmptyResponse

    /// The body of this request.
    var body: DeleteAccountRequestModel?

    /// The HTTP method for this request.
    let method: HTTPMethod = .delete

    /// The URL path for this request.
    var path: String = "/accounts"
}
