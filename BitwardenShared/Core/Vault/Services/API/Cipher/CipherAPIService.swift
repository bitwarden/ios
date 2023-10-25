import BitwardenSdk

/// A protocol for an API service used to make cipher requests.
///
protocol CipherAPIService {
    /// Performs an API request to add a new cipher to the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is adding.
    /// - Returns: The cipher that was added to the user's vault.
    ///
    func addCipher(_ cipher: Cipher) async throws -> CipherDetailsResponseModel
}

extension APIService: CipherAPIService {
    func addCipher(_ cipher: Cipher) async throws -> CipherDetailsResponseModel {
        try await apiService.send(AddCipherRequest(cipher: cipher))
    }
}
