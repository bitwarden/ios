import Foundation

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
        case twoFactorProviders = "TwoFactorProviders"
        case twoFactorProvidersData = "TwoFactorProviders2"
    }

    // MARK: Properties

    /// The captcha bypass token to use on subsequent requests to bypass captcha.
    let captchaBypassToken: String?

    /// The site code used to access hCaptcha.
    let siteCode: String?

    /// The user's SSO token.
    let ssoToken: String?

    /// The two-factor providers that the user has enabled and set up for their account.
    let twoFactorProviders: [String]?

    /// The two-factor providers data that the user has enabled and set up for their account.
    let twoFactorProvidersData: AuthMethodsData?
}

// MARK: - AuthMethodsData

/// The structure of the data returned in the two-factor authentication error.
public struct AuthMethodsData: Codable, Equatable, Sendable {
    /// Key names used for encoding and decoding.
    enum CodingKeys: String, CodingKey {
        case email = "1"
        case duo = "2"
        case organizationDuo = "6"
        case yubikey = "3"
        case webAuthn = "7"
    }

    /// Information for two factor authentication with Email
    let email: Email?

    /// Information for two factor authentication with Duo
    let duo: Duo?

    /// Information for two factor authentication with Duo for organizations
    let organizationDuo: Duo?

    /// Information for two factor authentication with Yubikey
    let yubikey: Yubikey?

    /// Information for two factor authentication with WebAuthn
    let webAuthn: WebAuthn?

    /// List of all available two factor authentication for the user
    /// This is necessary because authenticator is one possible option but has no information
    var providersAvailable: [String]?

    /// Constructor to initialise the AuthMethodsData empty
    init(
        email: Email? = nil,
        duo: Duo? = nil,
        organizationDuo: Duo? = nil,
        yubikey: Yubikey? = nil,
        webAuthn: WebAuthn? = nil
    ) {
        self.email = email
        self.duo = duo
        self.organizationDuo = organizationDuo
        self.yubikey = yubikey
        self.webAuthn = webAuthn
    }
}

// MARK: - Duo

/// Struct with information regarding Duo two factor authentication
public struct Duo: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey {
        case authUrl = "AuthUrl"
        case host = "Host"
        case signature = "Signature"
    }

    let authUrl, host, signature: String?
}

// MARK: - Email

/// Struct with information regarding Email two factor authentication
public struct Email: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey {
        case email = "Email"
    }

    /// Email used to send the code to verify 2fa
    let email: String?
}

// MARK: - WebAuthn

/// Struct with information regarding WebAuthn two factor authentication
public struct WebAuthn: Codable, Equatable, Sendable {
    /// Credentials allowed to be used to solve the challenge
    let allowCredentials: [AllowCredential]?

    /// Challenge sent from the server to be solved by an authenticator
    let challenge: String?

    /// Describes an error if one occurred
    let errorMessage: String?

    /// Identifier for the relying party
    let rpId: String?

    /// WebAuthn status
    let status: String?

    /// Available time to complete the challenge attestation
    let timeout: Int?

    /// Type of user verification to be applied in the attestation process
    let userVerification: String?
}

// MARK: - AllowCredential

/// Struct with information regarding user credentials for WebAuthn two factor authentication
public struct AllowCredential: Codable, Equatable, Sendable {
    /// Public key identifier
    let id: String?

    /// Credential type usually public-key
    let type: String?
}

// MARK: - Yubikey

/// Struct with information for two factor authentication with Yubikeys
public struct Yubikey: Codable, Equatable, Sendable {
    enum CodingKeys: String, CodingKey {
        case nfc = "Nfc"
    }

    /// Indicates if NFC is supported
    let nfc: Bool?
}
