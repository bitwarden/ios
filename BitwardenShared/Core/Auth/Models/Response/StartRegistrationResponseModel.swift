import Foundation
import Networking

// MARK: - StartRegistrationResponseModel

/// The response returned from the API upon creating an account.
///
struct StartRegistrationResponseModel: JSONResponse {
    static var decoder = JSONDecoder()

    // MARK: Properties

    /// The email verification token.
    var emailVerificationToken: String?

    /// The captcha bypass token returned in this response.
    var captchaBypassToken: String?
}
