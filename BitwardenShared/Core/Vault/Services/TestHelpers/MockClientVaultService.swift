import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockClientVaultService: ClientVaultService {
    var clientCiphers = MockClientCiphers()
    var clientCollections = MockClientCollections()
    var clientFolders = MockClientFolders()
    var clientPasswordHistory = MockClientPasswordHistory()
    var clientSends = MockClientSends()

    func ciphers() -> ClientCiphersProtocol {
        clientCiphers
    }

    func collections() -> ClientCollectionsProtocol {
        clientCollections
    }

    func folders() -> ClientFoldersProtocol {
        clientFolders
    }

    func passwordHistory() -> ClientPasswordHistoryProtocol {
        clientPasswordHistory
    }

    func sends() -> ClientSendsProtocol {
        clientSends
    }
}

// MARK: - MockClientCiphers

class MockClientCiphers: ClientCiphersProtocol {
    var encryptError: Error?
    var encryptedCiphers = [CipherView]()

    func decrypt(cipher: Cipher) async throws -> CipherView {
        CipherView(cipher: cipher)
    }

    func decryptList(ciphers: [Cipher]) async throws -> [CipherListView] {
        ciphers.map(CipherListView.init)
    }

    func encrypt(cipherView: CipherView) async throws -> Cipher {
        encryptedCiphers.append(cipherView)
        if let encryptError {
            throw encryptError
        }
        return Cipher(cipherView: cipherView)
    }
}

// MARK: - MockClientCollections

class MockClientCollections: ClientCollectionsProtocol {
    func decrypt(collection: Collection) async throws -> CollectionView {
        fatalError("Not implemented yet")
    }

    func decryptList(collections: [Collection]) async throws -> [CollectionView] {
        fatalError("Not implemented yet")
    }
}

// MARK: - MockClientFolders

class MockClientFolders: ClientFoldersProtocol {
    func decrypt(folder: Folder) async throws -> FolderView {
        FolderView(folder: folder)
    }

    func decryptList(folders: [Folder]) async throws -> [FolderView] {
        folders.map(FolderView.init)
    }

    func encrypt(folder: FolderView) async throws -> Folder {
        fatalError("Not implemented yet")
    }
}

// MARK: - MockClientPasswordHistory

class MockClientPasswordHistory: ClientPasswordHistoryProtocol {
    func decryptList(list: [PasswordHistory]) async throws -> [PasswordHistoryView] {
        fatalError("Not implemented yet")
    }

    func encrypt(passwordHistory: PasswordHistoryView) async throws -> PasswordHistory {
        fatalError("Not implemented yet")
    }
}

// MARK: - MockClientSends

class MockClientSends: ClientSendsProtocol {
    func decrypt(send: Send) async throws -> SendView {
        fatalError("Not implemented yet")
    }

    func decryptBuffer(send: Send, buffer: Data) async throws -> Data {
        fatalError("Not implemented yet")
    }

    func decryptFile(send: Send, encryptedFilePath: String, decryptedFilePath: String) async throws {
        fatalError("Not implemented yet")
    }

    func decryptList(sends: [Send]) async throws -> [SendListView] {
        fatalError("Not implemented yet")
    }

    func encrypt(send: SendView) async throws -> Send {
        fatalError("Not implemented yet")
    }

    func encryptBuffer(send: Send, buffer: Data) async throws -> Data {
        fatalError("Not implemented yet")
    }

    func encryptFile(send: Send, decryptedFilePath: String, encryptedFilePath: String) async throws {
        fatalError("Not implemented yet")
    }
}
