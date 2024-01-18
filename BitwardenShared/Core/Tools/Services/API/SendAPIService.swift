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

    /// Performs an API request to update a send in the user's vault.
    ///
    /// - Parameter send: The send that the user is updating.
    /// - Returns: The send that was updated in the user's vault.
    ///
    func updateSend(_ send: Send) async throws -> SendResponseModel
}

extension APIService: SendAPIService {
    func addSend(_ send: Send) async throws -> SendResponseModel {
        try await apiService.send(AddSendRequest(send: send))
    }

    func updateSend(_ send: Send) async throws -> SendResponseModel {
        try await apiService.send(UpdateSendRequest(send: send))
    }
}
