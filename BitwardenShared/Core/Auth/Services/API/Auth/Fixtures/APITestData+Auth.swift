extension APITestData {
    // MARK: Identity Token

    static let identityTokenSuccess = loadFromJsonBundle(resource: "IdentityTokenSuccess")
    static let identityTokenCaptchaError = loadFromJsonBundle(resource: "IdentityTokenCaptchaFailure")
    static let identityTokenRefresh = loadFromJsonBundle(resource: "identityTokenRefresh")
    static let identityTokenTwoFactorError = loadFromJsonBundle(resource: "IdentityTokenTwoFactorFailure")
    static let preValidateSingleSignOn = loadFromJsonBundle(resource: "preValidateSingleSignOn")
    static let singleSignOnDetails = loadFromJsonBundle(resource: "singleSignOnDetails")
}
