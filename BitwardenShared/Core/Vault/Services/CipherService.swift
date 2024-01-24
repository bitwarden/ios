import BitwardenSdk
import Combine
import Foundation

// MARK: - CipherService

/// A protocol for a `CipherService` which manages syncing and updates to the user's ciphers.
///
protocol CipherService {
    /// Adds a cipher for the current user both in the backend and in local storage.
    ///
    /// - Parameter cipher: The cipher to add.
    ///
    func addCipherWithServer(_ cipher: Cipher) async throws

    /// Delete a cipher's attachment for the current user both in the backend and in local storage.
    ///
    /// - Parameters:
    ///   - attachmentId: The id of the attachment to delete.
    ///   - cipherId: The id of the cipher that owns the attachment.
    ///
    /// - Returns: The updated cipher with one less attachment.
    ///
    func deleteAttachmentWithServer(attachmentId: String, cipherId: String) async throws -> Cipher?

    /// Deletes a cipher for the current user both in the backend and in local storage.
    ///
    /// - Parameter id: The id of cipher item to be deleted.
    ///
    func deleteCipherWithServer(id: String) async throws

    /// Attempt to fetch a cipher for the current user with the given id.
    ///
    /// - Parameter id: The id of the cipher to find.
    /// - Returns: The cipher if it was found and `nil` if not.
    ///
    func fetchCipher(withId id: String) async throws -> Cipher?

    /// Replaces the persisted list of ciphers for the current user.
    ///
    /// - Parameters:
    ///   - ciphers: The updated list of ciphers for the user.
    ///   - userId: The user ID associated with the ciphers.
    ///
    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws

    /// Restores a cipher from trash both in the backend and in local storage.
    ///
    /// - Parameters:
    ///  - id: The id of the cipher to be restored.
    ///  - cipher: The cipher that the user is restoring.
    ///
    func restoreCipherWithServer(id: String, _ cipher: Cipher) async throws

    /// Save an attachment to a cipher for the current user, both in the backend and in local storage.
    ///
    /// - Parameters:
    ///   - cipherId: The id of the cipher to add the attachment to.
    ///   - attachment: The encrypted attachment data to save.
    ///
    /// - Returns: The updated cipher with one more attachment.
    ///
    func saveAttachmentWithServer(cipherId: String, attachment: AttachmentEncryptResult) async throws -> Cipher

    /// Shares a cipher with an organization and updates the locally stored data.
    ///
    /// - Parameter cipher: The cipher to share.
    ///
    func shareCipherWithServer(_ cipher: Cipher) async throws

    /// Soft deletes a cipher for the current user both in the backend and in local storage.
    ///
    /// - Parameter cipher: The  cipher item to be soft deleted.
    ///
    func softDeleteCipherWithServer(id: String, _ cipher: Cipher) async throws

    /// Updates the cipher's collections for the current user both in the backend and in local storage.
    ///
    /// - Parameter cipher: The cipher to update.
    ///
    func updateCipherCollectionsWithServer(_ cipher: Cipher) async throws

    /// Updates the cipher for the current user both in the backend and in local storage.
    ///
    /// - Parameter cipher: The cipher to update.
    ///
    func updateCipherWithServer(_ cipher: Cipher) async throws

    // MARK: Publishers

    /// A publisher for the list of ciphers for the current user.
    ///
    /// - Returns: The list of encrypted ciphers.
    ///
    func ciphersPublisher() async throws -> AnyPublisher<[Cipher], Error>
}

// MARK: - DefaultCipherService

class DefaultCipherService: CipherService {
    // MARK: Properties

    /// The service used to make cipher related API requests.
    private let cipherAPIService: CipherAPIService

    /// The data store for managing the persisted ciphers for the user.
    private let cipherDataStore: CipherDataStore

    /// The service used to make file related API requests.
    private let fileAPIService: FileAPIService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultCipherService`.
    ///
    /// - Parameters:
    ///   - cipherAPIService: The service used to make cipher related API requests.
    ///   - cipherDataStore: The data store for managing the persisted ciphers for the user.
    ///   - fileAPIService: The service used to make file related API requests.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        cipherAPIService: CipherAPIService,
        cipherDataStore: CipherDataStore,
        fileAPIService: FileAPIService,
        stateService: StateService
    ) {
        self.cipherAPIService = cipherAPIService
        self.cipherDataStore = cipherDataStore
        self.fileAPIService = fileAPIService
        self.stateService = stateService
    }
}

extension DefaultCipherService {
    func addCipherWithServer(_ cipher: Cipher) async throws {
        let userId = try await stateService.getActiveAccountId()

        // Add the cipher in the backend.
        var response: CipherDetailsResponseModel
        if cipher.collectionIds.isEmpty {
            response = try await cipherAPIService.addCipher(cipher)
        } else {
            response = try await cipherAPIService.addCipherWithCollections(cipher)
        }

        // The API doesn't return the collectionIds, so manually add them back.
        response.collectionIds = cipher.collectionIds

        // Add the cipher in local storage.
        try await cipherDataStore.upsertCipher(Cipher(responseModel: response), userId: userId)
    }

    func deleteAttachmentWithServer(attachmentId: String, cipherId: String) async throws -> Cipher? {
        let userId = try await stateService.getActiveAccountId()

        // Delete attachment from the backend.
        _ = try await cipherAPIService.deleteAttachment(withID: attachmentId, cipherId: cipherId)

        // Remove the attachment from the cipher.
        guard let cipher = try await cipherDataStore.fetchCipher(withId: cipherId, userId: userId) else { return nil }
        var attachments = cipher.attachments ?? []
        if let index = attachments.firstIndex(where: { $0.id == attachmentId }) {
            attachments.remove(at: index)
        }
        let updatedCipher = cipher.update(attachments: attachments)

        // Update the cipher in local storage.
        try await cipherDataStore.upsertCipher(updatedCipher, userId: userId)

        // Return the updated cipher.
        return updatedCipher
    }

    func deleteCipherWithServer(id: String) async throws {
        let userId = try await stateService.getActiveAccountId()

        // Delete cipher from the backend.
        _ = try await cipherAPIService.deleteCipher(withID: id)

        // Delete cipher from local storage.
        try await cipherDataStore.deleteCipher(id: id, userId: userId)
    }

    func fetchCipher(withId id: String) async throws -> Cipher? {
        let userId = try await stateService.getActiveAccountId()
        return try await cipherDataStore.fetchCipher(withId: id, userId: userId)
    }

    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        try await cipherDataStore.replaceCiphers(ciphers.map(Cipher.init), userId: userId)
    }

    func restoreCipherWithServer(id: String, _ cipher: Cipher) async throws {
        let userID = try await stateService.getActiveAccountId()

        // Restore cipher from backend.
        _ = try await cipherAPIService.restoreCipher(withID: id)

        // Restore cipher from local storage
        try await cipherDataStore.upsertCipher(cipher, userId: userID)
    }

    func saveAttachmentWithServer(cipherId: String, attachment: AttachmentEncryptResult) async throws -> Cipher {
        let userId = try await stateService.getActiveAccountId()

        // Create the cipher attachment in the backend
        let response = try await cipherAPIService.saveAttachment(
            cipherId: cipherId,
            fileName: attachment.attachment.fileName,
            fileSize: Int(attachment.attachment.size ?? ""),
            key: attachment.attachment.key
        )

        // Upload the attachment data to the server.
        try await fileAPIService.uploadCipherAttachment(
            attachmentId: response.attachmentId,
            cipherId: response.cipherResponse.id,
            data: attachment.contents,
            fileName: attachment.attachment.fileName ?? "",
            type: response.fileUploadType,
            url: response.url
        )

        // Update the cipher in local storage.
        let updatedCipher = Cipher(responseModel: response.cipherResponse)
        try await cipherDataStore.upsertCipher(updatedCipher, userId: userId)

        // Return the updated cipher.
        return updatedCipher
    }

    func shareCipherWithServer(_ cipher: Cipher) async throws {
        let userId = try await stateService.getActiveAccountId()

        // Share the cipher from the backend.
        var response = try await cipherAPIService.shareCipher(cipher)

        // The API doesn't return the collectionIds, so manually add them back.
        response.collectionIds = cipher.collectionIds

        // Update the cipher in local storage.
        try await cipherDataStore.upsertCipher(Cipher(responseModel: response), userId: userId)
    }

    func softDeleteCipherWithServer(id: String, _ cipher: BitwardenSdk.Cipher) async throws {
        let userId = try await stateService.getActiveAccountId()

        // Soft delete cipher from the backend.
        _ = try await cipherAPIService.softDeleteCipher(withID: id)

        // Soft delete cipher from local storage.
        try await cipherDataStore.upsertCipher(cipher, userId: userId)
    }

    func updateCipherCollectionsWithServer(_ cipher: Cipher) async throws {
        let userId = try await stateService.getActiveAccountId()

        // Update the cipher collections in the backend.
        try await cipherAPIService.updateCipherCollections(cipher)

        // Update the cipher collections in local storage.
        try await cipherDataStore.upsertCipher(cipher, userId: userId)
    }

    func updateCipherWithServer(_ cipher: Cipher) async throws {
        let userId = try await stateService.getActiveAccountId()

        // Update the cipher in the backend.
        var response = try await cipherAPIService.updateCipher(cipher)

        // The API doesn't return the collectionIds, so manually add them back.
        response.collectionIds = cipher.collectionIds

        // Update the cipher in local storage.
        try await cipherDataStore.upsertCipher(Cipher(responseModel: response), userId: userId)
    }

    // MARK: Publishers

    func ciphersPublisher() async throws -> AnyPublisher<[Cipher], Error> {
        let userId = try await stateService.getActiveAccountId()
        return cipherDataStore.cipherPublisher(userId: userId)
    }
}
