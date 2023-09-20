// MARK: - AccountAPIService

/// A protocol for an API service used to make account requests.
///
protocol AccountAPIService {
    /// Creates an API call for when the user submits an account creation form.
    ///
    /// - Parameter body: The body to be included in the request.
    /// - Returns: Data returned from the `CreateAccountRequest`.
    ///
    func createNewAccount(body: CreateAccountRequestModel) async throws -> CreateAccountResponseModel

    /// Sends an API call for completing the pre-login step in the auth flow.
    ///
    /// - Parameter email: The email address that the user is attempting to sign in with.
    /// - Returns: Information necessary to complete the next step in the auth flow.
    ///
    func preLogin(email: String) async throws -> PreLoginResponseModel
}

// MARK: - APIService

extension APIService: AccountAPIService {
    func createNewAccount(body: CreateAccountRequestModel) async throws -> CreateAccountResponseModel {
        let request = CreateAccountRequest(body: body)
        return try await identityService.send(request)
    }

    func preLogin(email: String) async throws -> PreLoginResponseModel {
        let body = PreLoginRequestBodyModel(email: email)
        let request = PreLoginRequest(body: body)
        let response = try await identityService.send(request)
        return response
    }
}
