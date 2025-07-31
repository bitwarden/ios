import Networking

// MARK: - OrganizationAutoEnrollStatusResponseModel

/// The response returned from the API when requesting the auto-enroll status for an organization.
///
struct OrganizationAutoEnrollStatusResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The organization's ID.
    let id: String

    /// Whether reset password is enabled for the organization.
    let resetPasswordEnabled: Bool
}
