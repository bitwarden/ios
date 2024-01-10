import BitwardenSdk

/// A protocol for an API service used to make send requests.
///
protocol SendAPIService {
    /// Performs an API request to add a new send to the user's vault.
    ///
    /// - Parameter send: The send that the user is adding.
    /// - Returns: The send that was added to the user's vault.
    ///
    func addSend(_ send: Send) async throws -> SendResponseModel
}

extension APIService: SendAPIService {
    func addSend(_ send: Send) async throws -> SendResponseModel {
        try await apiService.send(AddSendRequest(send: send))
    }
}
