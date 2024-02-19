import Foundation
import Networking

// MARK: - IdentityTokenRequestError

/// Errors that can occur when sending an `IdentityTokenRequest`.
enum IdentityTokenRequestError: Error, Equatable {
    /// Captcha is required for this login attempt.
    ///
    /// - Parameter hCaptchaSiteCode: The site code to use when authenticating with hCaptcha.
    ///
    case captchaRequired(hCaptchaSiteCode: String)

    /// Two-factor authentication is required for this login attempt.
    ///
    /// - Parameters:
    ///   - authMethodsData: The information about the available auth methods.
    ///   - ssoToken: The sso token, which is non-nil if the user is using single sign on.
    ///   - captchaBypassToken: A captcha bypass token, which allows the user to bypass the next captcha prompt.
    ///
    case twoFactorRequired(_ authMethodsData: AuthMethodsData, _ ssoToken: String?, _ captchaBypassToken: String?)
}

// MARK: - IdentityTokenRequest

/// Data model for performing a identity token request.
///
struct IdentityTokenRequest: Request {
    // MARK: Types

    typealias Response = IdentityTokenResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: IdentityTokenRequestModel? {
        requestModel
    }

    /// HTTP headers to be sent in the request.
    var headers: [String: String] {
        guard case let .password(email, _) = requestModel.authenticationMethod else {
            return [:]
        }
        return ["Auth-Email": Data(email.utf8).base64EncodedString().urlEncoded()]
    }

    /// The HTTP method for this request.
    let method = HTTPMethod.post

    /// The URL path for this request.
    let path = "/connect/token"

    /// The request details to include in the body of the request.
    let requestModel: IdentityTokenRequestModel

    // MARK: Initialization

    /// Initialize an `IdentityTokenRequest`.
    ///
    /// - Parameter requestModel: The request details to include in the body of the request.
    ///
    init(requestModel: IdentityTokenRequestModel) {
        self.requestModel = requestModel
    }

    // MARK: Methods

    func validate(_ response: HTTPResponse) throws {
        switch response.statusCode {
        case 400:
            guard let errorModel = try? JSONDecoder().decode(
                IdentityTokenErrorModel.self,
                from: response.body
            ) else { return }

            if let twoFactorProviders = errorModel.twoFactorProviders {
                throw IdentityTokenRequestError.twoFactorRequired(
                    twoFactorProviders,
                    errorModel.ssoToken,
                    errorModel.captchaBypassToken
                )
            } else if let siteCode = errorModel.siteCode {
                // Throw the captcha error if the captcha site key can be found.
                throw IdentityTokenRequestError.captchaRequired(hCaptchaSiteCode: siteCode)
            }
        default:
            return
        }
    }
}
