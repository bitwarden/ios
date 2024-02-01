import Foundation
import Networking

/// API request model for fetching an identity token.
///
struct IdentityTokenRequestModel {
    // MARK: Types

    /// The methods used to authenticate a user.
    enum AuthenticationMethod {
        /// The user is authenticating with an authentication code
        case authorizationCode(code: String, codeVerifier: String, redirectUri: String)

        /// The user is authenticating with a username and password.
        case password(username: String, password: String)
    }

    // MARK: Properties

    /// The type of authentication method used.
    let authenticationMethod: AuthenticationMethod

    /// The response token returned from the captcha provider.
    var captchaToken: String?

    /// The device's details.
    let deviceInfo: DeviceInfo

    /// The id of the associated login with device request, if applicable.
    let loginRequestId: String?

    /// The two-factor authentication code.
    var twoFactorCode: String?

    /// The two-factor authentication method.
    var twoFactorMethod: TwoFactorAuthMethod?

    /// The two-factor authentication remember setting.
    var twoFactorRemember: Bool?
}

extension IdentityTokenRequestModel: FormURLEncodedRequestBody {
    var values: [URLQueryItem] {
        var queryItems = [URLQueryItem]()

        queryItems.append(contentsOf: [
            URLQueryItem(name: "scope", value: "api offline_access"),
            URLQueryItem(name: "client_id", value: Constants.clientType),

            URLQueryItem(name: "deviceIdentifier", value: deviceInfo.identifier),
            URLQueryItem(name: "deviceName", value: deviceInfo.name),
            URLQueryItem(name: "deviceType", value: String(deviceInfo.type)),
        ])

        switch authenticationMethod {
        case let .authorizationCode(code, codeVerifier, redirectUri):
            queryItems.append(contentsOf: [
                URLQueryItem(name: "grant_type", value: "authorization_code"),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "code_verifier", value: codeVerifier),
                URLQueryItem(name: "redirect_uri", value: redirectUri),
            ])
        case let .password(username, password):
            queryItems.append(contentsOf: [
                URLQueryItem(name: "grant_type", value: "password"),
                URLQueryItem(name: "username", value: username),
                URLQueryItem(name: "password", value: password),
            ])
        }

        if let captchaToken {
            queryItems.append(URLQueryItem(name: "captchaResponse", value: captchaToken))
        }

        if let loginRequestId {
            queryItems.append(URLQueryItem(name: "authRequest", value: loginRequestId))
        }

        if let twoFactorCode, let twoFactorMethod, let twoFactorRemember {
            queryItems.append(contentsOf: [
                URLQueryItem(name: "twoFactorToken", value: twoFactorCode),
                URLQueryItem(name: "twoFactorProvider", value: "\(twoFactorMethod.rawValue)"),
                URLQueryItem(name: "twoFactorRemember", value: twoFactorRemember ? "1" : "0"),
            ])
        }

        return queryItems
    }
}
