extension APITestData {
    // MARK: Identity Token

    static let authRequestSuccess = loadFromJsonBundle(resource: "AuthRequest")
    static let authRequestsSuccess = loadFromJsonBundle(resource: "AuthRequests")
    static let emptyResponse = APITestData(data: "{}".data(using: .utf8)!)
    static let nilResponse = APITestData(data: "".data(using: .utf8)!)
    static let identityTokenSuccess = loadFromJsonBundle(resource: "IdentityTokenSuccess")
    static let identityTokenWithMasterPasswordPolicy = loadFromJsonBundle(
        resource: "IdentityTokenWithMasterPasswordPolicy"
    )
    static let identityTokenSuccessTwoFactorToken = loadFromJsonBundle(resource: "IdentityTokenSuccessTwoFactorToken")
    static let identityTokenCaptchaError = loadFromJsonBundle(resource: "IdentityTokenCaptchaFailure")
    static let identityTokenKeyConnector = loadFromJsonBundle(resource: "IdentityTokenKeyConnector")
    static let identityTokenKeyConnectorMasterPassword = loadFromJsonBundle(
        resource: "IdentityTokenKeyConnectorMasterPassword"
    )
    static let identityTokenNoMasterPassword = loadFromJsonBundle(resource: "IdentityTokenNoMasterPassword")
    static let identityTokenRefresh = loadFromJsonBundle(resource: "identityTokenRefresh")
    static let identityTokenTrustedDevice = loadFromJsonBundle(resource: "IdentityTokenTrustedDevice")
    static let identityTokenTwoFactorError = loadFromJsonBundle(resource: "IdentityTokenTwoFactorFailure")
    static let preValidateSingleSignOn = loadFromJsonBundle(resource: "preValidateSingleSignOn")
}
