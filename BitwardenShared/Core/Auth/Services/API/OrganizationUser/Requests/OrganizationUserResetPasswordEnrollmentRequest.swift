import Networking

// MARK: - OrganizationAutoEnrollStatusRequest

/// A networking request to enroll the user in password reset for an organization.
///
struct OrganizationUserResetPasswordEnrollmentRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of the request.
    var body: OrganizationUserResetPasswordEnrollmentRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    var method: HTTPMethod { .put }

    /// The identifier for the organization.
    let organizationId: String

    /// The URL path for this request.
    var path: String { "/organizations/\(organizationId)/users/\(userId)/reset-password-enrollment" }

    /// The request details to include in the body of the request.
    let requestModel: OrganizationUserResetPasswordEnrollmentRequestModel

    /// The user's ID.
    let userId: String
}
