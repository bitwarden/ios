extension APITestData {
    // MARK: Create Account

    static let createAccountRequest = loadFromJsonBundle(resource: "CreateAccountRequest")
    static let createAccountResponse = loadFromJsonBundle(resource: "CreateAccountSuccess")
    static let hibpLeakedPasswords = loadFromBundle(resource: "hibpLeakedPasswords", extension: "txt")

    // MARK: Pre-Login

    static let preLoginSuccess = loadFromJsonBundle(resource: "PreLoginSuccess")
}
