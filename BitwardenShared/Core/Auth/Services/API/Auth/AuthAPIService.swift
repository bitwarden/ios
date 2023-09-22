/// A protocol for an API service used to make auth requests.
///
protocol AuthAPIService {
    /// Performs the identity token request and returns the response.
    ///
    /// - Parameter request: The access token to authenticate the user.
    /// - Returns: The identity token response.
    ///
    func getIdentityToken(_ request: IdentityTokenRequestModel) async throws -> IdentityTokenResponseModel
}

extension APIService: AuthAPIService {
    func getIdentityToken(_ request: IdentityTokenRequestModel) async throws -> IdentityTokenResponseModel {
        try await identityService.send(IdentityTokenRequest(requestModel: request))
    }
}
