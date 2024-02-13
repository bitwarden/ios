// MARK: - AuthMethodsData

/// The structure of the data returned in the two-factor authentication error.
public typealias AuthMethodsData = [String: [String: AnyCodable?]?]

// MARK: - IdentityTokenErrorModel

/// An error model for `IdentityTokenRequest`.
///
struct IdentityTokenErrorModel: Codable {
    // MARK: Types

    /// Key names used for encoding and decoding.
    enum CodingKeys: String, CodingKey {
        case captchaBypassToken = "CaptchaBypassToken"
        case siteCode = "HCaptcha_SiteKey"
        case ssoToken = "SsoEmail2faSessionToken"
        case twoFactorProviders = "TwoFactorProviders2"
    }

    // MARK: Properties

    /// The captcha bypass token to use on subsequent requests to bypass captcha.
    let captchaBypassToken: String?

    /// The site code used to access hCaptcha.
    let siteCode: String?

    /// The user's SSO token.
    let ssoToken: String?

    /// The two-factor providers that the user has enabled and set up for their account.
    let twoFactorProviders: AuthMethodsData?
}
