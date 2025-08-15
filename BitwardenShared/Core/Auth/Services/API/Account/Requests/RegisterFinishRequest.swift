import BitwardenKit
import Foundation
import Networking

// MARK: - RegisterFinishRequest

/// The API request sent when submitting an account creation form.
///
struct RegisterFinishRequest: Request {
    typealias Response = RegisterFinishResponseModel
    typealias Body = RegisterFinishRequestModel

    /// The body of this request.
    var body: RegisterFinishRequestModel?

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    var path: String = "/accounts/register/finish"

    /// Creates a new `RegisterFinishRequest` instance.
    ///
    /// - Parameter body: The body of the request.
    ///
    init(body: RegisterFinishRequestModel) {
        self.body = body
    }

    // MARK: Methods

    func validate(_ response: HTTPResponse) throws {
        switch response.statusCode {
        case 400 ..< 500:
            guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

            throw ServerError.error(errorResponse: errorResponse)
        default:
            return
        }
    }
}
