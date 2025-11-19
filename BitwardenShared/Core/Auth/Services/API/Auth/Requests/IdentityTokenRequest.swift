import Foundation
import Networking

// MARK: - IdentityTokenRequestError

/// Errors that can occur when sending an `IdentityTokenRequest`.
enum IdentityTokenRequestError: Error, Equatable {
    /// The encryption key migration is required.
    case encryptionKeyMigrationRequired

    /// The new device is not verified.
    case newDeviceNotVerified

    /// Two-factor authentication is required for this login attempt.
    ///
    /// - Parameters:
    ///   - authMethodsData: The information about the available auth methods.
    ///   - masterPasswordPolicy: The master password policies that the org has enabled.
    ///   - ssoToken: The sso token, which is non-nil if the user is using single sign on.
    ///
    case twoFactorRequired(
        _ authMethodsData: AuthMethodsData,
        _ masterPasswordPolicy: MasterPasswordPolicyResponseModel?,
        _ ssoToken: String?,
    )

    /// Two factor providers aren't configured.
    case twoFactorProvidersNotConfigured
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
            guard let errorModel = try? IdentityTokenErrorModel.decoder.decode(
                IdentityTokenErrorModel.self,
                from: response.body,
            ) else { return }

            if let twoFactorProvidersData = errorModel.twoFactorProvidersData {
                guard twoFactorProvidersData.providersAvailable != nil else {
                    throw IdentityTokenRequestError.twoFactorProvidersNotConfigured
                }
                throw IdentityTokenRequestError.twoFactorRequired(
                    twoFactorProvidersData,
                    errorModel.masterPasswordPolicy,
                    errorModel.ssoToken,
                )
            } else if let error = errorModel.error,
                      error == IdentityTokenError.deviceError {
                throw IdentityTokenRequestError.newDeviceNotVerified
            } else if let error = errorModel.error,
                      let errorMessage = errorModel.errorDetails?.message,
                      error == IdentityTokenError.invalidGrant,
                      errorMessage.contains(IdentityTokenError.encryptionKeyMigrationRequired) {
                throw IdentityTokenRequestError.encryptionKeyMigrationRequired
            }
        default:
            return
        }
    }
}
