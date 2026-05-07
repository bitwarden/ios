import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import BitwardenSdkMocks
import Foundation

@testable import AuthenticatorShared

class MockVaultClientService: VaultClientService {
    var clientAttachments = MockAttachmentsClientProtocol()
    var clientCiphers = MockClientCiphers()
    var clientCollections: MockCollectionsClientProtocol = {
        let mock = MockCollectionsClientProtocol()
        mock.decryptClosure = { CollectionView(collection: $0) }
        mock.decryptListClosure = { $0.map(CollectionView.init) }
        return mock
    }()

    var clientFolders: MockFoldersClientProtocol = {
        let mock = MockFoldersClientProtocol()
        mock.decryptClosure = { FolderView(folder: $0) }
        mock.decryptListClosure = { $0.map(FolderView.init) }
        mock.encryptClosure = { Folder(folderView: $0) }
        return mock
    }()

    var clientPasswordHistory: MockPasswordHistoryClientProtocol = {
        let mock = MockPasswordHistoryClientProtocol()
        mock.encryptClosure = { PasswordHistory(passwordHistoryView: $0) }
        mock.decryptListClosure = { $0.map(PasswordHistoryView.init) }
        return mock
    }()

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

    func generateTOTPCode(for _: String, date: Date?) throws -> TOTPCodeModel {
        let code = try generateTOTPCodeResult.get()
        return TOTPCodeModel(
            code: code,
            codeGenerationDate: date ?? timeProvider.presentTime,
            period: totpPeriod,
        )
    }

    func passwordHistory() -> PasswordHistoryClientProtocol {
        clientPasswordHistory
    }
}

// MARK: - MockClientCiphers

class MockClientCiphers: CiphersClientProtocol {
    var decryptResult: (Cipher) throws -> CipherView = { cipher in
        CipherView(cipher: cipher)
    }

    var decryptFido2CredentialsResult = [BitwardenSdk.Fido2CredentialView]()
    var decryptListWithFailuresResult: DecryptCipherListResult?
    var encryptCipherResult: Result<EncryptionContext, Error>?
    var encryptError: Error?
    var encryptedCiphers = [CipherView]()
    var moveToOrganizationCipher: CipherView?
    var moveToOrganizationOrganizationId: String?
    var moveToOrganizationCalled: Bool?
    var moveToOrganizationResult: Result<CipherView, Error> = .success(.fixture())
    var prepareCiphersForBulkShareResult: Result<[EncryptionContext], Error> = .success([])

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
        ciphers.map(CipherListView.init)
    }

    func decryptListWithFailures(ciphers: [Cipher]) -> DecryptCipherListResult {
        decryptListWithFailuresResult ?? DecryptCipherListResult(
            successes: ciphers.map(CipherListView.init),
            failures: [],
        )
    }

    func encrypt(cipherView: CipherView) throws -> BitwardenSdk.EncryptionContext {
        encryptedCiphers.append(cipherView)
        if let encryptError {
            throw encryptError
        }
        return try encryptCipherResult?.get() ?? EncryptionContext(
            encryptedFor: "1", cipher: Cipher(cipherView: cipherView),
        )
    }

    func moveToOrganization(
        cipher: CipherView,
        organizationId: Uuid,
    ) throws -> CipherView {
        moveToOrganizationCipher = cipher
        moveToOrganizationOrganizationId = organizationId
        return try moveToOrganizationResult.get()
    }

    func prepareCiphersForBulkShare(
        ciphers: [CipherView],
        organizationId: OrganizationId,
        collectionIds: [CollectionId],
    ) async throws -> [EncryptionContext] {
        try prepareCiphersForBulkShareResult.get()
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
