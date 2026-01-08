import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

class MockCipherService: CipherService {
    var addCipherWithServerCiphers = [Cipher]()
    var addCipherWithServerEncryptedFor: String?
    var addCipherWithServerResult: Result<Void, Error> = .success(())

    var cipherCountResult: Result<Int, Error> = .success(0)

    var cipherChangesSubject = CurrentValueSubject<CipherChange, Error>(
        .upserted(.fixture()), // stub data that will be dropped and not published.
    )

    var ciphersSubject = CurrentValueSubject<[Cipher], Error>([])

    var deleteAttachmentWithServerAttachmentId: String?
    var deleteAttachmentWithServerResult: Result<Cipher?, Error> = .success(.fixture())

    var deleteCipherWithLocalStorageId: String?
    var deleteCipherWithLocalStorageResult: Result<Void, Error> = .success(())

    var downloadAttachmentId: String?
    var downloadAttachmentResult: Result<URL?, Error> = .success(nil)

    var fetchCipherId: String?
    var fetchCipherByIdResult: ((String) -> Result<Cipher?, Error>)?
    var fetchCipherResult: Result<Cipher?, Error> = .success(nil)

    var fetchAllCiphersCalled = false
    var fetchAllCiphersResult: Result<[Cipher], Error> = .success([])

    var deleteCipherId: String?
    var deleteCipherWithServerResult: Result<Void, Error> = .success(())

    var replaceCiphersCiphers: [CipherDetailsResponseModel]?
    var replaceCiphersUserId: String?
    var replaceCiphersError: Error?

    var restoredCipherId: String?
    var restoredCipher: Cipher?
    var restoreWithServerResult: Result<Void, Error> = .success(())

    var softDeleteCipherId: String?
    var softDeleteCipher: Cipher?
    var softDeleteWithServerResult: Result<Void, Error> = .success(())

    var saveAttachmentWithServerCipher: Cipher?
    var saveAttachmentWithServerResult: Result<Cipher, Error> = .success(.fixture())

    var shareCipherWithServerCiphers = [Cipher]()
    var shareCipherWithServerEncryptedFor: String?
    var shareCipherWithServerResult: Result<Void, Error> = .success(())

    var syncCipherWithServerId: String?
    var syncCipherWithServerResult: Result<Void, Error> = .success(())

    var updateCipherWithLocalStorageCiphers = [BitwardenSdk.Cipher]()
    var updateCipherWithLocalStorageResult: Result<Void, Error> = .success(())

    var updateCipherWithServerCiphers = [Cipher]()
    var updateCipherWithServerEncryptedFor: String?
    var updateCipherWithServerResult: Result<Void, Error> = .success(())

    var updateCipherCollectionsWithServerCiphers = [Cipher]()
    var updateCipherCollectionsWithServerResult: Result<Void, Error> = .success(())

    func addCipherWithServer(_ cipher: Cipher, encryptedFor: String) async throws {
        addCipherWithServerCiphers.append(cipher)
        addCipherWithServerEncryptedFor = encryptedFor
        try addCipherWithServerResult.get()
    }

    func cipherCount() async throws -> Int {
        try cipherCountResult.get()
    }

    func deleteAttachmentWithServer(attachmentId: String, cipherId _: String) async throws -> Cipher? {
        deleteAttachmentWithServerAttachmentId = attachmentId
        return try deleteAttachmentWithServerResult.get()
    }

    func deleteCipherWithLocalStorage(id: String) async throws {
        deleteCipherWithLocalStorageId = id
        return try deleteCipherWithLocalStorageResult.get()
    }

    func deleteCipherWithServer(id: String) async throws {
        deleteCipherId = id
        try deleteCipherWithServerResult.get()
    }

    func downloadAttachment(withId id: String, cipherId _: String) async throws -> URL? {
        downloadAttachmentId = id
        return try downloadAttachmentResult.get()
    }

    func fetchAllCiphers() async throws -> [Cipher] {
        fetchAllCiphersCalled = true
        return try fetchAllCiphersResult.get()
    }

    func fetchCipher(withId id: String) async throws -> Cipher? {
        fetchCipherId = id
        guard let fetchCipherByIdResult else {
            return try fetchCipherResult.get()
        }
        return try fetchCipherByIdResult(id).get()
    }

    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        replaceCiphersCiphers = ciphers
        replaceCiphersUserId = userId
        if let replaceCiphersError {
            throw replaceCiphersError
        }
    }

    func restoreCipherWithServer(id: String, _ cipher: Cipher) async throws {
        restoredCipherId = id
        restoredCipher = cipher
        try restoreWithServerResult.get()
    }

    func saveAttachmentWithServer(cipher: Cipher, attachment _: AttachmentEncryptResult) async throws -> Cipher {
        saveAttachmentWithServerCipher = cipher
        return try saveAttachmentWithServerResult.get()
    }

    func shareCipherWithServer(_ cipher: Cipher, encryptedFor: String) async throws {
        shareCipherWithServerCiphers.append(cipher)
        shareCipherWithServerEncryptedFor = encryptedFor
        try shareCipherWithServerResult.get()
    }

    func softDeleteCipherWithServer(id: String, _ cipher: Cipher) async throws {
        softDeleteCipherId = id
        softDeleteCipher = cipher
        try softDeleteWithServerResult.get()
    }

    func syncCipherWithServer(withId id: String) async throws {
        syncCipherWithServerId = id
        return try syncCipherWithServerResult.get()
    }

    func updateCipherWithLocalStorage(_ cipher: Cipher) async throws {
        updateCipherWithLocalStorageCiphers.append(cipher)
        return try updateCipherWithLocalStorageResult.get()
    }

    func updateCipherWithServer(_ cipher: Cipher, encryptedFor: String) async throws {
        updateCipherWithServerCiphers.append(cipher)
        updateCipherWithServerEncryptedFor = encryptedFor
        try updateCipherWithServerResult.get()
    }

    func updateCipherCollectionsWithServer(_ cipher: Cipher) async throws {
        updateCipherCollectionsWithServerCiphers.append(cipher)
        try updateCipherCollectionsWithServerResult.get()
    }

    func cipherChangesPublisher() async throws -> AnyPublisher<CipherChange, Error> {
        cipherChangesSubject.dropFirst().eraseToAnyPublisher()
    }

    func ciphersPublisher() async throws -> AnyPublisher<[Cipher], Error> {
        ciphersSubject.eraseToAnyPublisher()
    }
}
