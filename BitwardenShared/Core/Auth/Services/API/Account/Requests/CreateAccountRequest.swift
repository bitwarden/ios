import Foundation
import Networking

// MARK: - CreateAccountRequestError

/// Errors that can occur when sending a `CreateAccountRequest`.
enum CreateAccountRequestError: Error, Equatable {
    /// Captcha is required when creating an account.
    ///
    /// - Parameter hCaptchaSiteCode: The site code to use when authenticating with hCaptcha.
    case captchaRequired(hCaptchaSiteCode: String)
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
        case 400:
            guard let object = try? JSONSerialization.jsonObject(with: response.body) as? [String: Any],
                  let validationErrors = object["validationErrors"] as? [String: Any],
                  let siteCodes = validationErrors["HCaptcha_SiteKey"] as? [String],
                  let siteCode = siteCodes.first
            else { return }

            // Only throw the captcha error if the captcha site key can be found. Otherwise, this must be
            // some other type of error.
            throw CreateAccountRequestError.captchaRequired(hCaptchaSiteCode: siteCode)
        default:
            return
        }
    }
}
