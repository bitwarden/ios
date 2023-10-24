extension APITestData {
    // MARK: Create Account

    static let createAccountAccountAlreadyExists = loadFromJsonBundle(resource: "CreateAccountAccountAlreadyExists")
    static let createAccountCaptchaFailure = loadFromJsonBundle(resource: "CreateAccountCaptchaFailure")
    static let createAccountEmailExceedsMaxLength = loadFromJsonBundle(resource: "CreateAccountEmailExceedsMaxLength")
    static let createAccountHintTooLong = loadFromJsonBundle(resource: "CreateAccountHintTooLong")
    static let createAccountInvalidEmailFormat = loadFromJsonBundle(resource: "CreateAccountInvalidEmailFormat")
    static let createAccountNilValidationErrors = loadFromJsonBundle(resource: "CreateAccountNilValidationErrors")
    static let createAccountRequest = loadFromJsonBundle(resource: "CreateAccountRequest")
    static let createAccountSuccess = loadFromJsonBundle(resource: "CreateAccountSuccess")
    static let hibpLeakedPasswords = loadFromBundle(resource: "hibpLeakedPasswords", extension: "txt")

    // MARK: Pre-Login

    static let preLoginSuccess = loadFromJsonBundle(resource: "PreLoginSuccess")
}
