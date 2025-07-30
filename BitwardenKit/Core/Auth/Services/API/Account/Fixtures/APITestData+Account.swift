import Foundation
import TestHelpers

public extension APITestData {
    // MARK: Account Revision Date

    /// Test data for an account revision date.
    static func accountRevisionDate( // swiftlint:disable:this type_contents_order
        _ date: Date = Date(timeIntervalSince1970: 1_704_067_200)
    ) -> APITestData {
        APITestData(data: Data(String(date.timeIntervalSince1970 * 1000).utf8))
    }

    // MARK: Create Account

    /// Test data of an invalid model state with no validation errors.
    static let createAccountNilValidationErrors = loadFromJsonBundle(
        resource: "CreateAccountNilValidationErrors",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Test data with a validation error of "User verification failed."
    static let deleteAccountRequestFailure = loadFromJsonBundle(
        resource: "DeleteAccountRequestFailure",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Test data with several leaked passwords.
    static let hibpLeakedPasswords = loadFromBundle(
        resource: "hibpLeakedPasswords",
        extension: "txt",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Test data with an invalid username/password error.
    static let responseValidationError = loadFromJsonBundle(
        resource: "ResponseValidationError",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    // MARK: Pre-Login

    /// Test data for prelogin success.
    static let preLoginSuccess = loadFromJsonBundle(
        resource: "PreLoginSuccess",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    // MARK: Register Finish

    /// Test data with a validation error of "Email 'j@a.com' is already taken."
    static let registerFinishAccountAlreadyExists = loadFromJsonBundle(
        resource: "RegisterFinishAccountAlreadyExists",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Test data with a CAPTCHA validation error.
    static let registerFinishCaptchaFailure = loadFromJsonBundle(
        resource: "RegisterFinishCaptchaFailure",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Test data with a validation error of
    /// "The field MasterPasswordHint must be a string with a maximum length of 50."
    static let registerFinishHintTooLong = loadFromJsonBundle(
        resource: "RegisterFinishHintTooLong",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Test data with a validation error of "The Email field is not a supported e-mail address format."
    static let registerFinishInvalidEmailFormat = loadFromJsonBundle(
        resource: "RegisterFinishInvalidEmailFormat",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Test data of a request to create an account for `example@email.com`
    static let registerFinishRequest = loadFromJsonBundle(
        resource: "RegisterFinishRequest",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Test data of a successful account creation.
    static let registerFinishSuccess = loadFromJsonBundle(
        resource: "RegisterFinishSuccess",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    // MARK: Request Password Hint

    /// Test data for a failure for password hint.
    static let passwordHintFailure = loadFromJsonBundle(
        resource: "PasswordHintFailure",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    // MARK: Start Registration

    /// Test data with a validation error of "Email 'j@a.com' is already taken."
    static let startRegistrationEmailAlreadyExists = loadFromJsonBundle(
        resource: "StartRegistrationEmailAlreadyExists",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Test data with a validation error of "The field Email must be a string with a maximum length of 256."
    static let startRegistrationEmailExceedsMaxLength = loadFromJsonBundle(
        resource: "StartRegistrationEmailExceedsMaxLength",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Test data with a validation error of
    static let startRegistrationInvalidEmailFormat = loadFromJsonBundle(
        resource: "StartRegistrationInvalidEmailFormat",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Test data for success with a registration start.
    static let startRegistrationSuccess = loadFromBundle(
        resource: "StartRegistrationSuccess",
        extension: "txt",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    // MARK: Verify Email Token

    /// Test data indicating that the verify email token link has expired.
    static let verifyEmailTokenExpiredLink = loadFromJsonBundle(
        resource: "VerifyEmailTokenExpiredLink",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )
}
