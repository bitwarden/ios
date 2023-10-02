extension APITestData {
    // MARK: Identity Token

    static let identityToken = loadFromJsonBundle(resource: "IdentityTokenSuccess")
    static let identityTokenCaptchaError = loadFromJsonBundle(resource: "IdentityTokenCaptchaFailure")
    static let identityTokenRefresh = loadFromJsonBundle(resource: "identityTokenRefresh")
}
