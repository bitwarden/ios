import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockCipherService: CipherService {
    var addCipherWithServerCiphers = [Cipher]()
    var addCipherWithServerResult: Result<Void, Error> = .success(())

    var ciphersSubject = CurrentValueSubject<[Cipher], Error>([])

    var fetchCipherId: String?
    var fetchCipherResult: Result<Cipher?, Error> = .success(nil)

    var replaceCiphersCiphers: [CipherDetailsResponseModel]?
    var replaceCiphersUserId: String?

    var deleteCipherId: String?
    var deleteWithServerResult: Result<Void, Error> = .success(())

    var restoredCipherId: String?
    var restoredCipher: Cipher?
    var restoreWithServerResult: Result<Void, Error> = .success(())

    var softDeleteCipherId: String?
    var softDeleteCipher: Cipher?
    var softDeleteWithServerResult: Result<Void, Error> = .success(())

    var shareCipherWithServerCiphers = [Cipher]()
    var shareCipherWithServerResult: Result<Void, Error> = .success(())

    var updateCipherWithServerCiphers = [Cipher]()
    var updateCipherWithServerResult: Result<Void, Error> = .success(())

    var updateCipherCollectionsWithServerCiphers = [Cipher]()
    var updateCipherCollectionsWithServerResult: Result<Void, Error> = .success(())

    func addCipherWithServer(_ cipher: Cipher) async throws {
        addCipherWithServerCiphers.append(cipher)
        try addCipherWithServerResult.get()
    }

    func deleteCipherWithServer(id: String) async throws {
        deleteCipherId = id
        try deleteWithServerResult.get()
    }

    func fetchCipher(withId id: String) async throws -> Cipher? {
        fetchCipherId = id
        return try fetchCipherResult.get()
    }

    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        replaceCiphersCiphers = ciphers
        replaceCiphersUserId = userId
    }

    func restoreCipherWithServer(id: String, _ cipher: Cipher) async throws {
        restoredCipherId = id
        restoredCipher = cipher
        try restoreWithServerResult.get()
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

    func updateCipherWithServer(_ cipher: Cipher) async throws {
        updateCipherWithServerCiphers.append(cipher)
        try updateCipherWithServerResult.get()
    }

    func updateCipherCollectionsWithServer(_ cipher: Cipher) async throws {
        updateCipherCollectionsWithServerCiphers.append(cipher)
        try updateCipherCollectionsWithServerResult.get()
    }

    func ciphersPublisher() async throws -> AnyPublisher<[BitwardenSdk.Cipher], Error> {
        ciphersSubject.eraseToAnyPublisher()
    }
}
