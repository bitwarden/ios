import BitwardenSdk

// MARK: - CipherAPIServiceError

/// The errors thrown from a `CipherAPIService`.
///
enum CipherAPIServiceError: Error {
    /// The cipher is missing an id and cannot be updated.
    case updateMissingId
}

// MARK: - CipherAPIService

/// A protocol for an API service used to make cipher requests.
///
protocol CipherAPIService {
    /// Performs an API request to add a new cipher to the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is adding.
    /// - Returns: The cipher that was added to the user's vault.
    ///
    func addCipher(_ cipher: Cipher) async throws -> CipherDetailsResponseModel

    /// Performs an API request to update an existing cipher in the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is updating.
    /// - Returns: The cipher that was updated in the user's vault.
    ///
    func updateCipher(_ cipher: Cipher) async throws -> CipherDetailsResponseModel
}

extension APIService: CipherAPIService {
    func addCipher(_ cipher: Cipher) async throws -> CipherDetailsResponseModel {
        try await apiService.send(AddCipherRequest(cipher: cipher))
    }

    func updateCipher(_ cipher: Cipher) async throws -> CipherDetailsResponseModel {
        let updateRequest = try UpdateCipherRequest(cipher: cipher)
        return try await apiService.send(updateRequest)
    }
}
