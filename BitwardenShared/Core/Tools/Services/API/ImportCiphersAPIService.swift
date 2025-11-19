import BitwardenSdk
import Networking

// MARK: - ImportCiphersAPIService

/// A protocol for an API service used to make import ciphers requests.
///
protocol ImportCiphersAPIService {
    /// Performs an API request to import ciphers in the vault.
    /// - Parameters:
    ///   - ciphers: The ciphers to import.
    ///   - folders: The folders to import.
    ///   - folderRelationships: The cipher<->folder relationships map. The key is the cipher index
    ///    and the value is the folder index in their respective arrays.
    func importCiphers(
        ciphers: [Cipher],
        folders: [Folder],
        folderRelationships: [(key: Int, value: Int)],
    ) async throws -> EmptyResponse
}

extension APIService: ImportCiphersAPIService {
    func importCiphers(
        ciphers: [Cipher],
        folders: [Folder],
        folderRelationships: [(key: Int, value: Int)],
    ) async throws -> EmptyResponse {
        try await apiService
            .send(
                ImportCiphersRequest(
                    ciphers: ciphers,
                    folders: folders,
                    folderRelationships: folderRelationships,
                ),
            )
    }
}
