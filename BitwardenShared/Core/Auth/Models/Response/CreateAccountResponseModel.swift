import Foundation
import Networking

// MARK: - CreateAccountResponseModel

/// The response returned from the API upon creating an account.
///
struct CreateAccountResponseModel: JSONResponse {
    // MARK: Properties

    /// The captcha bypass token returned in this response.
    var captchaBypassToken: String?
}
