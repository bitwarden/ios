import BitwardenSdk

@testable import BitwardenShared

class MockImportCiphersService: ImportCiphersService {
    var importCiphersCalled = false
    var importCiphersCiphers: [Cipher]?
    var importCiphersError: Error?
    var importCiphersFolders: [Folder]?
    var importCiphersFolderRelationships: [(key: Int, value: Int)]?

    func importCiphers(
        ciphers: [Cipher],
        folders: [Folder],
        folderRelationships: [(key: Int, value: Int)],
    ) async throws {
        importCiphersCalled = true
        importCiphersCiphers = ciphers
        importCiphersFolders = folders
        importCiphersFolderRelationships = folderRelationships
        if let importCiphersError {
            throw importCiphersError
        }
    }
}
