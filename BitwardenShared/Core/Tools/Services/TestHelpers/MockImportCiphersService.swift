import BitwardenSdk

@testable import BitwardenShared

class MockImportCiphersService: ImportCiphersService {
    var importCiphersCalled = false
    var importCiphersEncryptionContexts: [EncryptionContext]?
    var importCiphersError: Error?
    var importCiphersFolderRelationships: [(key: Int, value: Int)]?
    var importCiphersFolders: [Folder]?

    func importCiphers(
        encryptionContexts: [EncryptionContext],
        folders: [Folder],
        folderRelationships: [(key: Int, value: Int)],
    ) async throws {
        importCiphersCalled = true
        importCiphersEncryptionContexts = encryptionContexts
        importCiphersFolderRelationships = folderRelationships
        importCiphersFolders = folders
        if let importCiphersError {
            throw importCiphersError
        }
    }
}
