import BitwardenKit
import Foundation

// MARK: - IdentityTokenErrors

/// Constants for the `error` type returned in `IdentityTokenErrorModel`.
///
enum IdentityTokenError {
    static let deviceError = "device_error"

    static let invalidGrant = "invalid_grant"

    static let encryptionKeyMigrationRequired = "Encryption key migration is required. Please log in to the web vault"
}

// MARK: - IdentityTokenErrorModel

/// An error model for `IdentityTokenRequest`.
///
struct IdentityTokenErrorModel: Codable {
    // MARK: Types

    /// Key names used for encoding and decoding.
    enum CodingKeys: String, CodingKey {
        case masterPasswordPolicy
        case ssoToken = "ssoEmail2faSessionToken"
        case twoFactorProvidersData = "twoFactorProviders2"
        case error
        case errorDetails = "errorModel"
    }

    static let decoder = JSONDecoder.pascalOrSnakeCaseDecoder

    // MARK: Properties

    /// The error type.
    let error: String?

    /// An `ErrorModel` object that provides more details about the error.
    let errorDetails: ErrorModel?

    /// The master password policies that the org has enabled.
    let masterPasswordPolicy: MasterPasswordPolicyResponseModel?

    /// The user's SSO token.
    let ssoToken: String?

    /// The two-factor providers data that the user has enabled and set up for their account.
    let twoFactorProvidersData: AuthMethodsData?
}

// MARK: - AuthMethodsData

/// The structure of the data returned in the two-factor authentication error.
public struct AuthMethodsData: Codable, Equatable, Sendable {
    /// Key names used for encoding and decoding.
    enum CodingKeys: String, CodingKey {
        case authenticator = "0"
        case email = "1"
        case duo = "2"
        case organizationDuo = "6"
        case yubikey = "3"
        case webAuthn = "7"
    }

    /// Whether authenticator provider is enabled.
    let authenticator: Bool

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
    var providersAvailable: [String]? {
        var providers: [String] = []
        if authenticator { providers.append(CodingKeys.authenticator.rawValue) }
        if email != nil { providers.append(CodingKeys.email.rawValue) }
        if duo != nil { providers.append(CodingKeys.duo.rawValue) }
        if organizationDuo != nil { providers.append(CodingKeys.organizationDuo.rawValue) }
        if yubikey != nil { providers.append(CodingKeys.yubikey.rawValue) }
        if webAuthn != nil { providers.append(CodingKeys.webAuthn.rawValue) }
        return providers.nilIfEmpty
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        email = try container.decodeIfPresent(Email.self, forKey: .email)
        duo = try container.decodeIfPresent(Duo.self, forKey: .duo)
        organizationDuo = try container.decodeIfPresent(Duo.self, forKey: .organizationDuo)
        yubikey = try container.decodeIfPresent(Yubikey.self, forKey: .yubikey)
        webAuthn = try container.decodeIfPresent(WebAuthn.self, forKey: .webAuthn)

        authenticator = container.contains(.authenticator)
    }

    /// Constructor to initialise the AuthMethodsData empty
    init(
        authenticator: Bool = false,
        email: Email? = nil,
        duo: Duo? = nil,
        organizationDuo: Duo? = nil,
        yubikey: Yubikey? = nil,
        webAuthn: WebAuthn? = nil,
    ) {
        self.authenticator = authenticator
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
    let authUrl, host, signature: String?
}

// MARK: - Email

/// Struct with information regarding Email two factor authentication
public struct Email: Codable, Equatable, Sendable {
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
    /// Indicates if NFC is supported
    let nfc: Bool?
}
