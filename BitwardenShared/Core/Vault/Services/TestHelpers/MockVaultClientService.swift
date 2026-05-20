import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import BitwardenSdkMocks
import Foundation

@testable import BitwardenShared

class MockVaultClientService: VaultClientService {
    var clientAttachments = MockAttachmentsClientProtocol()
    var clientCiphers: MockCiphersClientProtocol = {
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
        mock.moveToOrganizationReturnValue = .fixture()
        mock.prepareCiphersForBulkShareReturnValue = []
        return mock
    }()

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

    func generateTOTPCode(for _: String, date: Date?) throws -> BitwardenKit.TOTPCodeModel {
        let code = try generateTOTPCodeResult.get()
        return TOTPCodeModel(
            code: code,
            codeGenerationDate: date ?? timeProvider.presentTime,
            period: totpPeriod,
        )
    }

    func generateTOTPCode(
        for cipherListView: BitwardenSdk.CipherListView,
        date: Date?,
    ) throws -> BitwardenKit.TOTPCodeModel {
        generateTOTPCodeCipherParam = cipherListView
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
