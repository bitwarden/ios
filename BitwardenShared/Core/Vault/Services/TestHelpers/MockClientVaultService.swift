import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockClientVaultService: ClientVaultService {
    var clientCiphers = MockClientCiphers()
    var clientCollections = MockClientCollections()
    var clientFolders = MockClientFolders()
    var clientPasswordHistory = MockClientPasswordHistory()
    var clientSends = MockClientSends()
    var generateTOTPCodeResult: Result<String, Error> = .success("123456")
    var timeProvider = MockTimeProvider(.currentTime)
    var totpPeriod: UInt32 = 30

    func ciphers() -> ClientCiphersProtocol {
        clientCiphers
    }

    func collections() -> ClientCollectionsProtocol {
        clientCollections
    }

    func folders() -> ClientFoldersProtocol {
        clientFolders
    }

    func generateTOTPCode(for key: String, date: Date?) async throws -> BitwardenShared.TOTPCodeModel {
        let code = try generateTOTPCodeResult.get()
        return TOTPCodeModel(
            code: code,
            codeGenerationDate: date ?? timeProvider.presentTime,
            period: totpPeriod
        )
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
    func decrypt(collection _: Collection) async throws -> CollectionView {
        fatalError("Not implemented yet")
    }

    func decryptList(collections: [Collection]) async throws -> [CollectionView] {
        collections.map(CollectionView.init)
    }
}

// MARK: - MockClientFolders

class MockClientFolders: ClientFoldersProtocol {
    var decryptedFolders = [Folder]()
    var encryptError: Error?
    var encryptedFolders = [FolderView]()

    func decrypt(folder: Folder) async throws -> FolderView {
        FolderView(folder: folder)
    }

    func decryptList(folders: [Folder]) async throws -> [FolderView] {
        decryptedFolders = folders
        return folders.map(FolderView.init)
    }

    func encrypt(folder: FolderView) async throws -> Folder {
        encryptedFolders.append(folder)
        if let encryptError {
            throw encryptError
        }
        return Folder(folderView: folder)
    }
}

// MARK: - MockClientPasswordHistory

class MockClientPasswordHistory: ClientPasswordHistoryProtocol {
    var encryptedPasswordHistory = [PasswordHistoryView]()

    func decryptList(list: [PasswordHistory]) async throws -> [PasswordHistoryView] {
        list.map(PasswordHistoryView.init)
    }

    func encrypt(passwordHistory: PasswordHistoryView) async throws -> PasswordHistory {
        encryptedPasswordHistory.append(passwordHistory)
        return PasswordHistory(passwordHistoryView: passwordHistory)
    }
}

// MARK: - MockClientSends

class MockClientSends: ClientSendsProtocol {
    var decryptedSends: [Send] = []
    var encryptedSendViews: [SendView] = []
    var encryptedBuffers: [Data] = []

    func decrypt(send: Send) async throws -> SendView {
        decryptedSends.append(send)
        return SendView(send: send)
    }

    func decryptBuffer(send _: Send, buffer _: Data) async throws -> Data {
        fatalError("Not implemented yet")
    }

    func decryptFile(send _: Send, encryptedFilePath _: String, decryptedFilePath _: String) async throws {
        fatalError("Not implemented yet")
    }

    func decryptList(sends _: [Send]) async throws -> [BitwardenSdk.SendListView] {
        fatalError("Not implemented yet")
    }

    func encrypt(send sendView: SendView) async throws -> Send {
        encryptedSendViews.append(sendView)
        return Send(sendView: sendView)
    }

    func encryptBuffer(send _: Send, buffer: Data) async throws -> Data {
        encryptedBuffers.append(buffer)
        return buffer
    }

    func encryptFile(send _: Send, decryptedFilePath _: String, encryptedFilePath _: String) async throws {
        fatalError("Not implemented yet")
    }
}
