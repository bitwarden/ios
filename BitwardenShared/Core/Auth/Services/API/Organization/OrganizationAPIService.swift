/// A protocol for an API service used to make organization requests.
///
protocol OrganizationAPIService {
    /// Gets the auto-enroll status for an organization.
    ///
    /// - Parameter identifier: The organization identifier.
    /// - Returns: A `OrganizationAutoEnrollStatusResponseModel` containing the auto-enroll status.
    ///
    func getOrganizationAutoEnrollStatus(identifier: String) async throws -> OrganizationAutoEnrollStatusResponseModel

    /// Gets the keys for an organization.
    ///
    /// - Parameter organizationId: The organization's ID.
    /// - Returns: A `OrganizationKeysResponseModel` containing the organization's keys.
    ///
    func getOrganizationKeys(organizationId: String) async throws -> OrganizationKeysResponseModel

    /// Checks for the verified organization domains of an email for single sign on purposes.
    /// - Parameter email: The user's email address
    /// - Returns: A `SingleSignOnDomainsVerifiedResponse` with the verified domains list.
    func getSingleSignOnVerifiedDomains(email: String) async throws -> SingleSignOnDomainsVerifiedResponse

    /// Performs the API request to leave an organization.
    ///
    /// - Parameters:
    ///   - organizationId: The organization identifier for the organization the user wants to leave.
    ///
    func leaveOrganization(
        organizationId: String,
    ) async throws

    /// Performs the API request to revoke the current user's access to an organization.
    ///
    /// - Parameters:
    ///   - organizationId: The organization identifier for the organization the user wants to revoke access from.
    ///
    func revokeSelfFromOrganization(
        organizationId: String,
    ) async throws
}

extension APIService: OrganizationAPIService {
    func getOrganizationAutoEnrollStatus(identifier: String) async throws -> OrganizationAutoEnrollStatusResponseModel {
        try await apiService.send(OrganizationAutoEnrollStatusRequest(identifier: identifier))
    }

    func getOrganizationKeys(organizationId: String) async throws -> OrganizationKeysResponseModel {
        try await apiService.send(OrganizationKeysRequest(id: organizationId))
    }

    func getSingleSignOnVerifiedDomains(email: String) async throws -> SingleSignOnDomainsVerifiedResponse {
        try await apiUnauthenticatedService.send(SingleSignOnDomainsVerifiedRequest(email: email))
    }

    func leaveOrganization(organizationId: String) async throws {
        _ = try await apiService.send(
            OrganizationLeaveRequest(identifier: organizationId),
        )
    }

    func revokeSelfFromOrganization(organizationId: String) async throws {
        _ = try await apiService.send(
            OrganizationRevokeSelfRequest(organizationId: organizationId),
        )
    }
}
