import Foundation
import Networking

// MARK: - StartRegistrationResponseModel

/// The response returned from the API upon creating an account.
///
struct StartRegistrationResponseModel: Response {
    // MARK: Properties

    /// The email verification token.
    var token: String?

    /// The captcha bypass token returned in this response.
    var captchaBypassToken: String?

    init(response: HTTPResponse) {
        token = String(bytes: response.body, encoding: .utf8)
    }
}
