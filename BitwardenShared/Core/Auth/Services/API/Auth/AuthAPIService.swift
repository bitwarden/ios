/// A protocol for an API service used to make auth requests.
///
protocol AuthAPIService {
    /// Performs the identity token request and returns the response.
    ///
    /// - Parameter request: The user's authentication details.
    /// - Returns: The identity token response containing an access token.
    ///
    func getIdentityToken(_ request: IdentityTokenRequestModel) async throws -> IdentityTokenResponseModel

    /// Queries the API to pre-validate single-sign on for the requested organization identifier.
    ///
    /// - Parameter organizationIdentifier: The organization identifier.
    ///
    /// - Returns: A `PreValidateSingleSignOnResponse`.
    ///
    func preValidateSingleSignOn(organizationIdentifier: String) async throws -> PreValidateSingleSignOnResponse

    /// Performs the identity token refresh request to get a new access token.
    ///
    /// - Parameter request: The user's refresh token used to get a new access token.
    /// - Returns: The identity token refresh response containing a new access token.
    ///
    func refreshIdentityToken(refreshToken: String) async throws -> IdentityTokenRefreshResponseModel
}

extension APIService: AuthAPIService {
    func getIdentityToken(_ request: IdentityTokenRequestModel) async throws -> IdentityTokenResponseModel {
        try await identityService.send(IdentityTokenRequest(requestModel: request))
    }

    func preValidateSingleSignOn(organizationIdentifier: String) async throws -> PreValidateSingleSignOnResponse {
        let request = PreValidateSingleSignOnRequest(organizationIdentifier: organizationIdentifier)
        return try await identityService.send(request)
    }

    func refreshIdentityToken(refreshToken: String) async throws -> IdentityTokenRefreshResponseModel {
        try await identityService.send(IdentityTokenRefreshRequest(refreshToken: refreshToken))
    }
}
