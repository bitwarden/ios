import Networking

// MARK: - OrganizationUserResetPasswordEnrollmentRequestModel

/// API request model for enrolling a user in password reset.
///
struct OrganizationUserResetPasswordEnrollmentRequestModel: JSONRequestBody, Equatable {
    // swiftlint:disable:previous type_name

    // MARK: Properties

    /// The master password hash used to authenticate a user.
    let masterPasswordHash: String

    /// The organization encrypted user key used for password reset.
    let resetPasswordKey: String
}
