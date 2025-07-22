import BitwardenKitMocks
import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockVaultClientService: VaultClientService {
    var clientAttachments = MockClientAttachments()
    var clientCiphers = MockClientCiphers()
    var clientCollections = MockClientCollections()
    var clientFolders = MockClientFolders()
    var clientPasswordHistory = MockClientPasswordHistory()
    var generateTOTPCodeCipherParam: CipherListView?
    var generateTOTPCodeResult: Result<String, Error> = .success("123456")
    var timeProvider = MockTimeProvider(.currentTime)
    var totpPeriod: UInt32 = 30

    func attachments() -> AttachmentsClientProtocol {
        clientAttachments
    }

    func ciphers() -> CiphersClientProtocol {
        clientCiphers
    }

    func collections() -> CollectionsClientProtocol {
        clientCollections
    }

    func folders() -> FoldersClientProtocol {
        clientFolders
    }

    func generateTOTPCode(for _: String, date: Date?) throws -> BitwardenShared.TOTPCodeModel {
        let code = try generateTOTPCodeResult.get()
        return TOTPCodeModel(
            code: code,
            codeGenerationDate: date ?? timeProvider.presentTime,
            period: totpPeriod
        )
    }

    func generateTOTPCode(
        for cipherListView: BitwardenSdk.CipherListView,
        date: Date?
    ) throws -> BitwardenShared.TOTPCodeModel {
        generateTOTPCodeCipherParam = cipherListView
        let code = try generateTOTPCodeResult.get()
        return TOTPCodeModel(
            code: code,
            codeGenerationDate: date ?? timeProvider.presentTime,
            period: totpPeriod
        )
    }

    func passwordHistory() -> PasswordHistoryClientProtocol {
        clientPasswordHistory
    }
}

// MARK: - MockClientAttachments

class MockClientAttachments: AttachmentsClientProtocol {
    var encryptedFilePaths = [String]()
    var decryptedBuffers = [Data]()
    var encryptedBuffers = [Data]()

    func decryptBuffer(cipher _: Cipher, attachment _: AttachmentView, buffer: Data) throws -> Data {
        decryptedBuffers.append(buffer)
        return buffer
    }

    func decryptFile(
        cipher _: Cipher,
        attachment _: AttachmentView,
        encryptedFilePath: String,
        decryptedFilePath _: String
    ) throws {
        encryptedFilePaths.append(encryptedFilePath)
    }

    func encryptBuffer(
        cipher _: Cipher,
        attachment: AttachmentView,
        buffer: Data
    ) throws -> AttachmentEncryptResult {
        encryptedBuffers.append(buffer)
        return AttachmentEncryptResult(attachment: Attachment(attachmentView: attachment), contents: buffer)
    }

    func encryptFile(
        cipher _: Cipher,
        attachment: AttachmentView,
        decryptedFilePath _: String,
        encryptedFilePath _: String
    ) throws -> Attachment {
        Attachment(attachmentView: attachment)
    }
}

// MARK: - MockClientCiphers

class MockClientCiphers: CiphersClientProtocol {
    var decryptResult: (Cipher) throws -> CipherView = { cipher in
        CipherView(cipher: cipher)
    }

    var decryptFido2CredentialsResult = [BitwardenSdk.Fido2CredentialView]()
    var decryptListError: Error?
    var decryptListErrorWhenCiphers: (([Cipher]) -> Error?)?
    var decryptListReceivedCiphersInvocations: [[Cipher]] = []
    var decryptListWithFailuresReceivedCiphersInvocations: [[Cipher]] = [] // swiftlint:disable:this identifier_name
    var decryptListWithFailuresResult: DecryptCipherListResult?
    var decryptListWithFailuresResultClosure: (([Cipher]) -> DecryptCipherListResult)?
    var encryptCipherResult: Result<EncryptionContext, Error>?
    var encryptError: Error?
    var encryptedCiphers = [CipherView]()
    var moveToOrganizationCipher: CipherView?
    var moveToOrganizationOrganizationId: String?
    var moveToOrganizationCalled: Bool?
    var moveToOrganizationResult: Result<CipherView, Error> = .success(.fixture())

    func decrypt(cipher: Cipher) throws -> CipherView {
        try decryptResult(cipher)
    }

    func decryptFido2Credentials(cipherView: BitwardenSdk.CipherView) throws -> [BitwardenSdk.Fido2CredentialView] {
        guard cipherView.login?.fido2Credentials != nil else {
            return []
        }
        return decryptFido2CredentialsResult
    }

    func decryptList(ciphers: [Cipher]) throws -> [CipherListView] {
        if let decryptListError {
            throw decryptListError
        }
        if let decryptListErrorWhenCiphers, let error = decryptListErrorWhenCiphers(ciphers) {
            throw error
        }
        decryptListReceivedCiphersInvocations.append(ciphers)
        return ciphers.map { CipherListView(cipher: $0) }
    }

    func decryptListWithFailures(ciphers: [Cipher]) -> DecryptCipherListResult {
        decryptListWithFailuresReceivedCiphersInvocations.append(ciphers)
        if let decryptListWithFailuresResultClosure {
            return decryptListWithFailuresResultClosure(ciphers)
        }
        return decryptListWithFailuresResult ?? DecryptCipherListResult(
            successes: ciphers.map { CipherListView(cipher: $0) },
            failures: []
        )
    }

    func encrypt(cipherView: CipherView) throws -> EncryptionContext {
        encryptedCiphers.append(cipherView)
        if let encryptError {
            throw encryptError
        }
        return try encryptCipherResult?.get() ?? EncryptionContext(
            encryptedFor: "1",
            cipher: Cipher(cipherView: cipherView)
        )
    }

    func moveToOrganization(
        cipher: CipherView,
        organizationId: Uuid
    ) throws -> CipherView {
        moveToOrganizationCipher = cipher
        moveToOrganizationOrganizationId = organizationId
        return try moveToOrganizationResult.get()
    }
}

// MARK: - MockClientCollections

class MockClientCollections: CollectionsClientProtocol {
    var decryptListError: Error?

    func decrypt(collection _: Collection) throws -> CollectionView {
        fatalError("Not implemented yet")
    }

    func decryptList(collections: [Collection]) throws -> [CollectionView] {
        if let decryptListError {
            throw decryptListError
        }
        return collections.map(CollectionView.init)
    }
}

// MARK: - MockClientFolders

class MockClientFolders: FoldersClientProtocol {
    var decryptFolderValueToDecrypt: Folder?
    var decryptFolderResult: Result<FolderView?, Error> = .success(nil)

    var decryptedFolders = [Folder]()

    var encryptError: Error?
    var encryptedFolders = [FolderView]()

    func decrypt(folder: Folder) throws -> FolderView {
        decryptFolderValueToDecrypt = folder
        return try decryptFolderResult.get() ?? FolderView(folder: folder)
    }

    func decryptList(folders: [Folder]) throws -> [FolderView] {
        decryptedFolders = folders
        return folders.map(FolderView.init)
    }

    func encrypt(folder: FolderView) throws -> Folder {
        encryptedFolders.append(folder)
        if let encryptError {
            throw encryptError
        }
        return Folder(folderView: folder)
    }
}

// MARK: - MockClientPasswordHistory

class MockClientPasswordHistory: PasswordHistoryClientProtocol {
    var encryptedPasswordHistory = [PasswordHistoryView]()

    func decryptList(list: [PasswordHistory]) throws -> [PasswordHistoryView] {
        list.map(PasswordHistoryView.init)
    }

    func encrypt(passwordHistory: PasswordHistoryView) throws -> PasswordHistory {
        encryptedPasswordHistory.append(passwordHistory)
        return PasswordHistory(passwordHistoryView: passwordHistory)
    }
}

// MARK: - MockSendClient

class MockSendClient: SendClientProtocol {
    var decryptedSends: [Send] = []
    var encryptedSendViews: [SendView] = []
    var encryptedBuffers: [Data] = []

    func decrypt(send: Send) throws -> SendView {
        decryptedSends.append(send)
        return SendView(send: send)
    }

    func decryptBuffer(send _: Send, buffer _: Data) throws -> Data {
        fatalError("Not implemented yet")
    }

    func decryptFile(send _: Send, encryptedFilePath _: String, decryptedFilePath _: String) throws {
        fatalError("Not implemented yet")
    }

    func decryptList(sends _: [Send]) throws -> [BitwardenSdk.SendListView] {
        fatalError("Not implemented yet")
    }

    func encrypt(send sendView: SendView) throws -> Send {
        encryptedSendViews.append(sendView)
        return Send(sendView: sendView)
    }

    func encryptBuffer(send _: Send, buffer: Data) throws -> Data {
        encryptedBuffers.append(buffer)
        return buffer
    }

    func encryptFile(send _: Send, decryptedFilePath _: String, encryptedFilePath _: String) throws {
        fatalError("Not implemented yet")
    }
}
