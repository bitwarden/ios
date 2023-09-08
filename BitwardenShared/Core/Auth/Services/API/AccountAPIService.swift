// MARK: - AccountAPIService

/// A protocol for an API service used to make account requests.
///
protocol AccountAPIService {
    /// Creates an API call for when the user submits an account creation form.
    ///
    /// - Parameter body: The body to be included in the request.
    ///
    /// - Returns data returned from the `CreateAccountRequest`.
    ///
    func createNewAccount(body: CreateAccountRequestModel) async throws -> CreateAccountResponseModel
}

// MARK: - APIService

extension APIService: AccountAPIService {
    func createNewAccount(body: CreateAccountRequestModel) async throws -> CreateAccountResponseModel {
        let request = CreateAccountRequest(body: body)
        let response = try await apiService.send(request)
        return response
    }
}
