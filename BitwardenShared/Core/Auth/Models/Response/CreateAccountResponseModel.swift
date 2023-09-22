import Foundation
import Networking

// MARK: - CreateAccountResponseModel

/// The response returned from the API upon creating an account.
///
struct CreateAccountResponseModel: JSONResponse {
    static var decoder = JSONDecoder()

    // MARK: Properties

    /// The captcha bypass token returned in this response.
    var captchaBypassToken: String?
}
