import Foundation
import Networking

// MARK: - VerifyEmailTokenRequestError

/// Errors that can occur when sending a `VerifyEmailTokenRequest`.
enum VerifyEmailTokenRequestError: Error, Equatable {
    /// The token provided by email is expired or user is already used.
    ///
    case tokenExpired
}

// MARK: - VerificationEmailClickedRequest

/// The API request sent when verifying the token received by email.
///
struct VerifyEmailTokenRequest: Request {
    typealias Response = EmptyResponse

    typealias Body = VerifyEmailTokenRequestModel

    /// The body of this request.
    var body: VerifyEmailTokenRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    var path: String = "/accounts/register/verification-email-clicked"

    /// The request details to include in the body of the request.
    let requestModel: VerifyEmailTokenRequestModel

    // MARK: Methods

    func validate(_ response: HTTPResponse) throws {
        switch response.statusCode {
        case 400 ..< 500:
            guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

            if errorResponse.message.contains("Expired link") {
                throw VerifyEmailTokenRequestError.tokenExpired
            }

            throw ServerError.error(errorResponse: errorResponse)
        default:
            return
        }
    }
}
