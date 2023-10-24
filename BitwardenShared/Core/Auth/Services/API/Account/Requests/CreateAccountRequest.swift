import Foundation
import Networking

// MARK: - CreateAccountRequestError

/// Errors that can occur when sending a `CreateAccountRequest`.
enum CreateAccountRequestError: Error, Equatable {
    /// Captcha is required when creating an account.
    ///
    /// - Parameter hCaptchaSiteCode: The site code to use when authenticating with hCaptcha.
    case captchaRequired(hCaptchaSiteCode: String)

    /// A validation error occurred when creating an account.
    ///
    /// - Parameter errorResponse: The error response returned from the server.
    case serverError(_ errorResponse: ErrorResponseModel)
}

// MARK: - CreateAccountRequest

/// The API request sent when submitting an account creation form.
///
struct CreateAccountRequest: Request {
    typealias Response = CreateAccountResponseModel
    typealias Body = CreateAccountRequestModel

    /// The body of this request.
    var body: CreateAccountRequestModel?

    /// The HTTP method for this request.
    let method: HTTPMethod = .post

    /// The URL path for this request.
    var path: String = "/accounts/register"

    /// Creates a new `CreateAccountRequest` instance.
    ///
    /// - Parameter body: The body of the request.
    ///
    init(body: CreateAccountRequestModel) {
        self.body = body
    }

    // MARK: Methods

    func validate(_ response: HTTPResponse) throws {
        switch response.statusCode {
        case 400 ..< 500:
            guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

            if let siteCode = errorResponse.validationErrors?["HCaptcha_SiteKey"]?.first {
                throw CreateAccountRequestError.captchaRequired(hCaptchaSiteCode: siteCode)
            }

            throw CreateAccountRequestError.serverError(errorResponse)
        default:
            return
        }
    }
}
