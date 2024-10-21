import BitwardenSdk
import Foundation
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

    /// Performs an API request to delete an existing attachment in the user's vault.
    ///
    /// - Parameters:
    ///   - attachmentId: The id of the attachment to be deleted.
    ///   - cipherId: The id of the cipher that owns the attachment.
    ///
    /// - Returns: The `EmptyResponse`.
    ///
    func deleteAttachment(withID attachmentId: String, cipherId: String) async throws -> EmptyResponse

    /// Performs an API request to delete an existing cipher in the user's vault.
    ///
    /// - Parameter id: The cipher id that to be deleted.
    /// - Returns: The `EmptyResponse`.
    ///
    func deleteCipher(withID id: String) async throws -> EmptyResponse

    /// Get the information necessary to download an attachment.
    ///
    /// - Parameters:
    ///   - id: The id of the attachment to download.
    ///   - cipherId: The id of the cipher that owns the attachment.
    ///
    /// - Returns: The `DownloadAttachmentResponse`.
    ///
    func downloadAttachment(withId id: String, cipherId: String) async throws -> DownloadAttachmentResponse

    /// Download the raw data of an attachment from its remote location.
    ///
    /// - Parameter url: The url where the data is stored.
    ///
    /// - Returns: The url of the temporary file location if it was able to be downloaded.
    ///
    func downloadAttachmentData(from url: URL) async throws -> URL?

    /// Performs an API request to retrieve the details of a cipher.
    ///
    /// - Parameter id: The id of the cipher to be retrieved.
    /// - Returns: The details of the cipher.
    ///
    func getCipher(withId id: String) async throws -> CipherDetailsResponseModel

    /// Performs an API request to restore a cipher in the user's trash.
    ///
    /// - Parameter id: The id of the cipher to be restored.
    /// - Returns: The `EmptyResponse`.
    ///
    func restoreCipher(withID id: String) async throws -> EmptyResponse

    /// Performs an API request to create the attachment for the cipher in the backend.
    ///
    /// - Parameters:
    ///   - cipherId: The id of the cipher to add the attachment to.
    ///   - fileName: The name of the attachment.
    ///   - fileSize: The size of the attachment.
    ///   - key: The encryption key for the attachment.
    ///
    /// - Returns: The `SaveAttachmentResponse`.
    ///
    func saveAttachment(
        cipherId: String,
        fileName: String?,
        fileSize: Int?,
        key: String?
    ) async throws -> SaveAttachmentResponse

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

    func deleteAttachment(withID attachmentId: String, cipherId: String) async throws -> EmptyResponse {
        try await apiService.send(DeleteAttachmentRequest(attachmentId: attachmentId, cipherId: cipherId))
    }

    func deleteCipher(withID id: String) async throws -> EmptyResponse {
        try await apiService.send(DeleteCipherRequest(id: id))
    }

    func downloadAttachment(withId id: String, cipherId: String) async throws -> DownloadAttachmentResponse {
        try await apiService.send(DownloadAttachmentRequest(attachmentId: id, cipherId: cipherId))
    }

    func downloadAttachmentData(from url: URL) async throws -> URL? {
        try await apiUnauthenticatedService.download(from: URLRequest(url: url))
    }

    func getCipher(withId id: String) async throws -> CipherDetailsResponseModel {
        try await apiService.send(GetCipherRequest(cipherId: id))
    }

    func restoreCipher(withID id: String) async throws -> EmptyResponse {
        try await apiService.send(RestoreCipherRequest(id: id))
    }

    func saveAttachment(
        cipherId: String,
        fileName: String?,
        fileSize: Int?,
        key: String?
    ) async throws -> SaveAttachmentResponse {
        try await apiService.send(SaveAttachmentRequest(
            cipherId: cipherId,
            fileName: fileName,
            fileSize: fileSize,
            key: key
        ))
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
