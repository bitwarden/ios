import BitwardenSdk

// MARK: - SendAPIService

/// A protocol for an API service used to make send requests.
///
protocol SendAPIService {
    /// Performs an API request to add a file new send to the user's vault.
    ///
    /// - Parameters:
    ///   - send: The send that the user is adding.
    ///   - fileLength: The length of the file the user is adding.
    /// - Returns: The send that was added to the user's vault.
    ///
    func addFileSend(_ send: Send, fileLength: Int) async throws -> SendFileResponseModel

    /// Performs an API request to add a new text send to the user's vault.
    ///
    /// - Parameter send: The send that the user is adding.
    /// - Returns: The send that was added to the user's vault.
    ///
    func addTextSend(_ send: Send) async throws -> SendResponseModel

    /// Performs an API request to delete a send in the user's vault.
    ///
    /// - Parameter id: The id of the send that the user is deleting.
    ///
    func deleteSend(with id: String) async throws

    /// Performs an API request to retrieve a send in the user's vault.
    ///
    /// - Parameter id: The id of the send to retrieve.
    ///
    func getSend(with id: String) async throws -> SendResponseModel

    /// Performs an API request to remove the password from a send in the user's vault.
    ///
    /// - Parameter id: The id of the send that the user is remove the password from.
    ///
    func removePasswordFromSend(with id: String) async throws -> SendResponseModel

    /// Performs an API request to update a send in the user's vault.
    ///
    /// - Parameter send: The send that the user is updating.
    /// - Returns: The send that was updated in the user's vault.
    ///
    func updateSend(_ send: Send) async throws -> SendResponseModel
}

// MARK: - APIService

extension APIService: SendAPIService {
    func addFileSend(_ send: Send, fileLength: Int) async throws -> SendFileResponseModel {
        try await apiService.send(AddFileSendRequest(send: send, fileLength: fileLength))
    }

    func addTextSend(_ send: Send) async throws -> SendResponseModel {
        try await apiService.send(AddTextSendRequest(send: send))
    }

    func deleteSend(with id: String) async throws {
        _ = try await apiService.send(DeleteSendRequest(sendId: id))
    }

    func getSend(with id: String) async throws -> SendResponseModel {
        try await apiService.send(GetSendRequest(sendId: id))
    }

    func removePasswordFromSend(with id: String) async throws -> SendResponseModel {
        try await apiService.send(RemovePasswordFromSendRequest(sendId: id))
    }

    func updateSend(_ send: Send) async throws -> SendResponseModel {
        try await apiService.send(UpdateSendRequest(send: send))
    }
}
