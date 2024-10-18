import Foundation
import Networking

// MARK: - RegisterFinishResponseModel

/// The response returned from the API upon creating an account.
///
struct RegisterFinishResponseModel: JSONResponse {
    // MARK: Properties

    /// The captcha bypass token returned in this response.
    var captchaBypassToken: String?
}
