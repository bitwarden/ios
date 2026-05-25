import BitwardenKit
import BitwardenSdk
import BitwardenSdkMocks
import Foundation

public class MockVaultClientService: VaultClientService {
    public var clientAttachments = MockAttachmentsClientProtocol()
    public var clientCiphers: MockCiphersClientProtocol = {
        let mock = MockCiphersClientProtocol()
        mock.decryptClosure = { CipherView(cipher: $0) }
        mock.decryptFido2CredentialsReturnValue = []
        mock.decryptListClosure = { $0.map { CipherListView(cipher: $0) } }
        mock.decryptListWithFailuresClosure = { ciphers in
            DecryptCipherListResult(successes: ciphers.map { CipherListView(cipher: $0) }, failures: [])
        }
        mock.encryptClosure = { cipherView in
            EncryptionContext(encryptedFor: "1", cipher: Cipher(cipherView: cipherView))
        }
        mock.prepareCiphersForBulkShareReturnValue = []
        return mock
    }()

    public var clientCollections: MockCollectionsClientProtocol = {
        let mock = MockCollectionsClientProtocol()
        mock.decryptClosure = { CollectionView(collection: $0) }
        mock.decryptListClosure = { $0.map(CollectionView.init) }
        return mock
    }()

    public var clientFolders: MockFoldersClientProtocol = {
        let mock = MockFoldersClientProtocol()
        mock.decryptClosure = { FolderView(folder: $0) }
        mock.decryptListClosure = { $0.map(FolderView.init) }
        mock.encryptClosure = { Folder(folderView: $0) }
        return mock
    }()

    public var clientPasswordHistory: MockPasswordHistoryClientProtocol = {
        let mock = MockPasswordHistoryClientProtocol()
        mock.encryptClosure = { PasswordHistory(passwordHistoryView: $0) }
        mock.decryptListClosure = { $0.map(PasswordHistoryView.init) }
        return mock
    }()

    public var generateTOTPCodeCipherParam: CipherListView?
    public var generateTOTPCodeResult: Result<String, Error> = .success("123456")
    public var timeProvider = MockTimeProvider(.currentTime)
    public var totpPeriod: UInt32 = 30

    public init() {}

    public func attachments() -> AttachmentsClientProtocol {
        clientAttachments
    }

    public func ciphers() -> CiphersClientProtocol {
        clientCiphers
    }

    public func collections() -> CollectionsClientProtocol {
        clientCollections
    }

    public func folders() -> FoldersClientProtocol {
        clientFolders
    }

    public func generateTOTPCode(for _: String, date: Date?) throws -> TOTPCodeModel {
        let code = try generateTOTPCodeResult.get()
        return TOTPCodeModel(
            code: code,
            codeGenerationDate: date ?? timeProvider.presentTime,
            period: totpPeriod,
        )
    }

    public func generateTOTPCode(
        for cipherListView: CipherListView,
        date: Date?,
    ) throws -> TOTPCodeModel {
        generateTOTPCodeCipherParam = cipherListView
        let code = try generateTOTPCodeResult.get()
        return TOTPCodeModel(
            code: code,
            codeGenerationDate: date ?? timeProvider.presentTime,
            period: totpPeriod,
        )
    }

    public func passwordHistory() -> PasswordHistoryClientProtocol {
        clientPasswordHistory
    }
}
