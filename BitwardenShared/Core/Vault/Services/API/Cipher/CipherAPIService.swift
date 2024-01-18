import BitwardenSdk
import Networking

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

    /// Performs an API request to add a new cipher contained within one or more collections to the
    /// user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is adding.
    /// - Returns: The cipher that was added to the user's vault.
    ///
    func addCipherWithCollections(_ cipher: Cipher) async throws -> CipherDetailsResponseModel

    /// Performs an API request to delete an existing cipher in the user's vault.
    ///
    /// - Parameter id: The cipher id that to be deleted.
    /// - Returns: The `EmptyResponse`.
    ///
    func deleteCipher(withID id: String) async throws -> EmptyResponse

    /// Performs an API request to restore a cipher in the user's trash.
    ///
    /// - Parameter id: The cipher id that to be restored.
    /// - Returns: The `EmptyResponse`.
    ///
    func restoreCipher(withID id: String) async throws -> EmptyResponse

    /// Performs an API request to share a cipher with an organization.
    ///
    /// - Parameter cipher: The cipher to share.
    /// - Returns: The cipher that was shared with the organization.
    ///
    func shareCipher(_ cipher: Cipher) async throws -> CipherDetailsResponseModel

    /// Performs an API request to soft delete an existing cipher in the user's vault.
    ///
    /// - Parameter id: The cipher id that to be soft deleted.
    /// - Returns: The `EmptyResponse`.
    ///
    func softDeleteCipher(withID id: String) async throws -> EmptyResponse

    /// Performs an API request to update an existing cipher in the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is updating.
    /// - Returns: The cipher that was updated in the user's vault.
    ///
    func updateCipher(_ cipher: Cipher) async throws -> CipherDetailsResponseModel

    /// Performs an API request to update the collections that a cipher is included in.
    ///
    /// - Parameter: cipher: The cipher to update.
    ///
    func updateCipherCollections(_ cipher: Cipher) async throws
}

extension APIService: CipherAPIService {
    func addCipher(_ cipher: Cipher) async throws -> CipherDetailsResponseModel {
        try await apiService.send(AddCipherRequest(cipher: cipher))
    }

    func addCipherWithCollections(_ cipher: Cipher) async throws -> CipherDetailsResponseModel {
        try await apiService.send(AddCipherWithCollectionsRequest(cipher: cipher))
    }

    func deleteCipher(withID id: String) async throws -> EmptyResponse {
        try await apiService.send(DeleteCipherRequest(id: id))
    }

    func restoreCipher(withID id: String) async throws -> EmptyResponse {
        try await apiService.send(RestoreCipherRequest(id: id))
    }

    func shareCipher(_ cipher: Cipher) async throws -> CipherDetailsResponseModel {
        try await apiService.send(ShareCipherRequest(cipher: cipher))
    }

    func softDeleteCipher(withID id: String) async throws -> EmptyResponse {
        try await apiService.send(SoftDeleteCipherRequest(id: id))
    }

    func updateCipher(_ cipher: Cipher) async throws -> CipherDetailsResponseModel {
        let updateRequest = try UpdateCipherRequest(cipher: cipher)
        return try await apiService.send(updateRequest)
    }

    func updateCipherCollections(_ cipher: Cipher) async throws {
        _ = try await apiService.send(UpdateCipherCollectionsRequest(cipher: cipher))
    }
}
