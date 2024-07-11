import Foundation
import Networking

// MARK: - StartRegistrationRequest

/// The API request sent when starting the account creation.
///
struct StartRegistrationRequest: Request {
    typealias Response = StartRegistrationResponseModel

    typealias Body = StartRegistrationRequestModel

    /// The body of this request.
    var body: StartRegistrationRequestModel?

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    var path: String = "/accounts/register/send-verification-email"

    /// Creates a new `StartRegistrationRequest` instance.
    ///
    /// - Parameter body: The body of the request.
    ///
    init(body: StartRegistrationRequestModel) {
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
