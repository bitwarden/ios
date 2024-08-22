import Foundation
import Networking

// MARK: - CaptchaRequestModel

/// An object that contains the information necessary for performing a captcha flow.
///
struct CaptchaRequestModel: JSONRequestBody {
    // MARK: Static Properties

    static let encoder = JSONEncoder()

    // MARK: Properties

    /// The callback URL scheme. This url is opened once the captcha flow has completed (successfully or with an error).
    let callbackUri: String

    /// A localized string used as the web page's title.
    let captchaRequiredText: String

    /// A string representation of the user's locale.
    let locale: String

    /// The token used to authenticate with hCaptcha.
    let siteKey: String
}
