import BitwardenSdk
import Combine
import Foundation

// MARK: - ImportCiphersService

/// A protocol for a `ImportCiphersService` which manages importing credentials.
///
protocol ImportCiphersService {
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
    ) async throws
}

// MARK: - DefaultImportCiphersService

class DefaultImportCiphersService: ImportCiphersService {
    // MARK: Properties

    /// The service used to make import ciphers related API requests.
    private let importCiphersAPIService: ImportCiphersAPIService

    // MARK: Initialization

    /// Initialize a `DefaultCipherService`.
    ///
    /// - Parameters:
    ///   - importCiphersAPIService: The service used to make import ciphers related API requests.
    ///
    init(importCiphersAPIService: ImportCiphersAPIService) {
        self.importCiphersAPIService = importCiphersAPIService
    }
}

extension DefaultImportCiphersService {
    func importCiphers(
        ciphers: [Cipher],
        folders: [Folder],
        folderRelationships: [(key: Int, value: Int)],
    ) async throws {
        _ = try await importCiphersAPIService
            .importCiphers(
                ciphers: ciphers,
                folders: folders,
                folderRelationships: folderRelationships,
            )
    }
}
