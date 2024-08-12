import Foundation
import Networking

// MARK: - RegisterFinishRequestError

/// Errors that can occur when sending a `RegisterFinishRequest`.
enum RegisterFinishRequestError: Error, Equatable {
    /// Captcha is required when creating an account.
    ///
    /// - Parameter hCaptchaSiteCode: The site code to use when authenticating with hCaptcha.
    case captchaRequired(hCaptchaSiteCode: String)
}

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

            if let siteCode = errorResponse.validationErrors?["HCaptcha_SiteKey"]?.first {
                throw RegisterFinishRequestError.captchaRequired(hCaptchaSiteCode: siteCode)
            }

            throw ServerError.error(errorResponse: errorResponse)
        default:
            return
        }
    }
}
