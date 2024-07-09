import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

class MockCipherService: CipherService {
    var addCipherWithServerCiphers = [Cipher]()
    var addCipherWithServerResult: Result<Void, Error> = .success(())

    var ciphersSubject = CurrentValueSubject<[Cipher], Error>([])

    var deleteAttachmentWithServerAttachmentId: String?
    var deleteAttachmentWithServerResult: Result<Cipher?, Error> = .success(.fixture())

    var deleteCipherWithLocalStorageId: String?
    var deleteCipherWithLocalStorageResult: Result<Void, Error> = .success(())

    var downloadAttachmentId: String?
    var downloadAttachmentResult: Result<URL?, Error> = .success(nil)

    var fetchCipherId: String?
    var fetchCipherResult: Result<Cipher?, Error> = .success(nil)

    var fetchAllCiphersResult: Result<[Cipher], Error> = .success([])

    var deleteCipherId: String?
    var deleteCipherWithServerResult: Result<Void, Error> = .success(())

    var hasUnassignedCiphersCalled: Bool = false
    var hasUnassignedCiphersResult: Result<Bool, Error> = .success(false)

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
    var shareCipherWithServerResult: Result<Void, Error> = .success(())

    var syncCipherWithServerId: String?
    var syncCipherWithServerResult: Result<Void, Error> = .success(())

    var updateCipherWithLocalStorageCiphers = [BitwardenSdk.Cipher]()
    var updateCipherWithLocalStorageResult: Result<Void, Error> = .success(())

    var updateCipherWithServerCiphers = [Cipher]()
    var updateCipherWithServerResult: Result<Void, Error> = .success(())

    var updateCipherCollectionsWithServerCiphers = [Cipher]()
    var updateCipherCollectionsWithServerResult: Result<Void, Error> = .success(())

    func addCipherWithServer(_ cipher: Cipher) async throws {
        addCipherWithServerCiphers.append(cipher)
        try addCipherWithServerResult.get()
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
        try fetchAllCiphersResult.get()
    }

    func fetchCipher(withId id: String) async throws -> Cipher? {
        fetchCipherId = id
        return try fetchCipherResult.get()
    }

    func hasUnassignedCiphers() async throws -> Bool {
        hasUnassignedCiphersCalled = true
        return try hasUnassignedCiphersResult.get()
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

    func shareCipherWithServer(_ cipher: Cipher) async throws {
        shareCipherWithServerCiphers.append(cipher)
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

    func updateCipherWithServer(_ cipher: Cipher) async throws {
        updateCipherWithServerCiphers.append(cipher)
        try updateCipherWithServerResult.get()
    }

    func updateCipherCollectionsWithServer(_ cipher: Cipher) async throws {
        updateCipherCollectionsWithServerCiphers.append(cipher)
        try updateCipherCollectionsWithServerResult.get()
    }

    func ciphersPublisher() async throws -> AnyPublisher<[Cipher], Error> {
        ciphersSubject.eraseToAnyPublisher()
    }
}
