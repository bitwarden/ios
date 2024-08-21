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

    /// Query the API to determine if the user's email is able to use single sign on and if the organization
    /// identifier is already known.
    ///
    /// - Parameter email: The user's email address.
    /// - Returns: A `SingleSignOnDetailsResponse`.
    ///
    func getSingleSignOnDetails(email: String) async throws -> SingleSignOnDetailsResponse
}

extension APIService: OrganizationAPIService {
    func getOrganizationAutoEnrollStatus(identifier: String) async throws -> OrganizationAutoEnrollStatusResponseModel {
        try await apiService.send(OrganizationAutoEnrollStatusRequest(identifier: identifier))
    }

    func getOrganizationKeys(organizationId: String) async throws -> OrganizationKeysResponseModel {
        try await apiService.send(OrganizationKeysRequest(id: organizationId))
    }

    func getSingleSignOnDetails(email: String) async throws -> SingleSignOnDetailsResponse {
        try await apiUnauthenticatedService.send(SingleSignOnDetailsRequest(email: email))
    }
}
