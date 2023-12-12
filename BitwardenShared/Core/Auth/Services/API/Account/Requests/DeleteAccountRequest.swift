import Foundation
import Networking

// MARK: - DeleteAccountRequestError

/// Errors that can occur when sending a `DeleteAccountRequest`.
enum DeleteAccountRequestError: Error, Equatable {
    /// A validation error occurred when deleting an account.
    ///
    /// - Parameter errorResponse: The error response returned from the server.
    case serverError(_ errorResponse: ErrorResponseModel)
}

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

    // MARK: Methods

    func validate(_ response: HTTPResponse) throws {
        switch response.statusCode {
        case 400 ..< 500:
            guard let errorResponse = try? ErrorResponseModel(response: response) else { return }
            throw DeleteAccountRequestError.serverError(errorResponse)
        default:
            return
        }
    }
}
