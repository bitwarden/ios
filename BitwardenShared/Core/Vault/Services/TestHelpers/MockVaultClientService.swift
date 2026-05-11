import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import BitwardenSdkMocks
import Foundation

@testable import BitwardenShared

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
    var prepareCiphersForBulkShareCiphers: [CipherView]?
    var prepareCiphersForBulkShareOrganizationId: String?
    var prepareCiphersForBulkShareCollectionIds: [String]?
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
            failures: [],
        )
    }

    func encrypt(cipherView: CipherView) throws -> EncryptionContext {
        encryptedCiphers.append(cipherView)
        if let encryptError {
            throw encryptError
        }
        return try encryptCipherResult?.get() ?? EncryptionContext(
            encryptedFor: "1",
            cipher: Cipher(cipherView: cipherView),
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
        prepareCiphersForBulkShareCiphers = ciphers
        prepareCiphersForBulkShareOrganizationId = organizationId
        prepareCiphersForBulkShareCollectionIds = collectionIds
        return try prepareCiphersForBulkShareResult.get()
    }
}
