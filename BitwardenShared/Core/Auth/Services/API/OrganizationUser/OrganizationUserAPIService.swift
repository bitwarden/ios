/// A protocol for an API service used to make organization user requests.
///
protocol OrganizationUserAPIService {
    /// Performs the API request to enroll a user in password reset for an organization.
    ///
    /// - Parameters:
    ///   - organizationId: The organization for the user to enroll in password reset.
    ///   - requestModel: The request model containing the details needed to enroll the user in
    ///     password reset.
    ///   - userId: The user's ID.
    ///
    func organizationUserResetPasswordEnrollment(
        organizationId: String,
        requestModel: OrganizationUserResetPasswordEnrollmentRequestModel,
        userId: String
    ) async throws
}

extension APIService: OrganizationUserAPIService {
    func organizationUserResetPasswordEnrollment(
        organizationId: String,
        requestModel: OrganizationUserResetPasswordEnrollmentRequestModel,
        userId: String
    ) async throws {
        _ = try await apiService.send(
            OrganizationUserResetPasswordEnrollmentRequest(
                organizationId: organizationId,
                requestModel: requestModel,
                userId: userId
            )
        )
    }
}
