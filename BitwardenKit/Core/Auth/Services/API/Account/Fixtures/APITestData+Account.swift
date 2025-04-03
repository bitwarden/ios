import Foundation
import TestHelpers

public extension APITestData {
    // MARK: Account Revision Date

    /// Placeholder.
    static func accountRevisionDate( // swiftlint:disable:this type_contents_order
        _ date: Date = Date(timeIntervalSince1970: 1_704_067_200)
    ) -> APITestData {
        APITestData(data: Data(String(date.timeIntervalSince1970 * 1000).utf8))
    }

    // MARK: Create Account

    /// Placeholder.
    static let createAccountAccountAlreadyExists = loadFromJsonBundle(
        resource: "CreateAccountAccountAlreadyExists",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let createAccountCaptchaFailure = loadFromJsonBundle(
        resource: "CreateAccountCaptchaFailure",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let createAccountEmailExceedsMaxLength = loadFromJsonBundle(
        resource: "CreateAccountEmailExceedsMaxLength",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let createAccountHintTooLong = loadFromJsonBundle(
        resource: "CreateAccountHintTooLong",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let createAccountInvalidEmailFormat = loadFromJsonBundle(
        resource: "CreateAccountInvalidEmailFormat",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let createAccountNilValidationErrors = loadFromJsonBundle(
        resource: "CreateAccountNilValidationErrors",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let createAccountRequest = loadFromJsonBundle(
        resource: "CreateAccountRequest",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let createAccountSuccess = loadFromJsonBundle(
        resource: "CreateAccountSuccess",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let deleteAccountRequestFailure = loadFromJsonBundle(
        resource: "DeleteAccountRequestFailure",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let hibpLeakedPasswords = loadFromBundle(
        resource: "hibpLeakedPasswords",
        extension: "txt",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let responseValidationError = loadFromJsonBundle(
        resource: "ResponseValidationError",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    // MARK: Pre-Login

    /// Placeholder.
    static let preLoginSuccess = loadFromJsonBundle(
        resource: "PreLoginSuccess",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    // MARK: Request Password Hint

    /// Placeholder.
    static let passwordHintFailure = loadFromJsonBundle(
        resource: "PasswordHintFailure",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    // MARK: Start Registration

    /// Placeholder.
    static let startRegistrationEmailAlreadyExists = loadFromJsonBundle(
        resource: "StartRegistrationEmailAlreadyExists",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let startRegistrationEmailExceedsMaxLength = loadFromJsonBundle(
        resource: "StartRegistrationEmailExceedsMaxLength",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let startRegistrationInvalidEmailFormat = loadFromJsonBundle(
        resource: "StartRegistrationInvalidEmailFormat",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let startRegistrationCaptchaFailure = loadFromJsonBundle(
        resource: "StartRegistrationCaptchaFailure",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    /// Placeholder.
    static let startRegistrationSuccess = loadFromBundle(
        resource: "StartRegistrationSuccess",
        extension: "txt",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )

    // MARK: Verify Email Token

    /// Placeholder.
    static let verifyEmailTokenExpiredLink = loadFromJsonBundle(
        resource: "VerifyEmailTokenExpiredLink",
        bundle: BitwardenKitMocksBundleFinder.bundle
    )
}

class BitwardenKitMocksBundleFinder {
    static let bundle = Bundle(for: BitwardenKitMocksBundleFinder.self)
}
