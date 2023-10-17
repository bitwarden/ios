extension APITestData {
    // MARK: Create Account

    static let createAccountCaptchaFailure = loadFromJsonBundle(resource: "CreateAccountCaptchaFailure")
    static let createAccountRequest = loadFromJsonBundle(resource: "CreateAccountRequest")
    static let createAccountSuccess = loadFromJsonBundle(resource: "CreateAccountSuccess")
    static let hibpLeakedPasswords = loadFromBundle(resource: "hibpLeakedPasswords", extension: "txt")

    // MARK: Pre-Login

    static let preLoginSuccess = loadFromJsonBundle(resource: "PreLoginSuccess")
}
