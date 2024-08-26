import Foundation

extension APITestData {
    // MARK: Account Revision Date

    static func accountRevisionDate( // swiftlint:disable:this type_contents_order
        _ date: Date = Date(timeIntervalSince1970: 1_704_067_200)
    ) -> APITestData {
        APITestData(data: Data(String(date.timeIntervalSince1970 * 1000).utf8))
    }

    // MARK: Create Account

    static let createAccountAccountAlreadyExists = loadFromJsonBundle(resource: "CreateAccountAccountAlreadyExists")
    static let createAccountCaptchaFailure = loadFromJsonBundle(resource: "CreateAccountCaptchaFailure")
    static let createAccountEmailExceedsMaxLength = loadFromJsonBundle(resource: "CreateAccountEmailExceedsMaxLength")
    static let createAccountHintTooLong = loadFromJsonBundle(resource: "CreateAccountHintTooLong")
    static let createAccountInvalidEmailFormat = loadFromJsonBundle(resource: "CreateAccountInvalidEmailFormat")
    static let createAccountNilValidationErrors = loadFromJsonBundle(resource: "CreateAccountNilValidationErrors")
    static let createAccountRequest = loadFromJsonBundle(resource: "CreateAccountRequest")
    static let createAccountSuccess = loadFromJsonBundle(resource: "CreateAccountSuccess")
    static let deleteAccountRequestFailure = loadFromJsonBundle(resource: "DeleteAccountRequestFailure")
    static let hibpLeakedPasswords = loadFromBundle(resource: "hibpLeakedPasswords", extension: "txt")
    static let responseValidationError = loadFromJsonBundle(resource: "ResponseValidationError")

    // MARK: Pre-Login

    static let preLoginSuccess = loadFromJsonBundle(resource: "PreLoginSuccess")

    // MARK: Request Password Hint

    static let passwordHintFailure = loadFromJsonBundle(resource: "PasswordHintFailure")

    // MARK: Start Registration

    static let startRegistrationEmailAlreadyExists = loadFromJsonBundle(resource: "StartRegistrationEmailAlreadyExists")
    static let startRegistrationEmailExceedsMaxLength = loadFromJsonBundle(
        resource: "StartRegistrationEmailExceedsMaxLength"
    )
    static let startRegistrationInvalidEmailFormat = loadFromJsonBundle(resource: "StartRegistrationInvalidEmailFormat")
    static let startRegistrationCaptchaFailure = loadFromJsonBundle(resource: "StartRegistrationCaptchaFailure")
    static let startRegistrationSuccess = loadFromBundle(resource: "StartRegistrationSuccess", extension: "txt")

    // MARK: Verify Email Token

    static let verifyEmailTokenExpiredLink = loadFromJsonBundle(resource: "VerifyEmailTokenExpiredLink")
}
